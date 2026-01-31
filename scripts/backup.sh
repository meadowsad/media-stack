#!/bin/bash

# Media Automation Stack - Backup Script
# Backs up all configuration files to a timestamped archive

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-$HOME/media-stack-backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/media-stack-backup-$TIMESTAMP.tar.gz"

echo "====================================="
echo "Media Stack Backup"
echo "====================================="
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Backing up configuration..."
echo "Source: $STACK_DIR"
echo "Destination: $BACKUP_FILE"
echo ""

# Create backup
cd "$STACK_DIR"
tar -czf "$BACKUP_FILE" \
  --exclude='jellyfin/cache/*' \
  --exclude='jellyfin/transcodes/*' \
  --exclude='*/logs/*' \
  sabnzbd/ \
  sonarr/ \
  radarr/ \
  jellyfin/ \
  docker-compose.yml \
  .env 2>/dev/null || true

# Check if backup was created successfully
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup created successfully!"
    echo "   File: $BACKUP_FILE"
    echo "   Size: $BACKUP_SIZE"
    echo ""
    
    # Clean up old backups (keep last 7)
    echo "Cleaning up old backups (keeping last 7)..."
    cd "$BACKUP_DIR"
    ls -t media-stack-backup-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm
    
    echo ""
    echo "Existing backups:"
    ls -lh media-stack-backup-*.tar.gz 2>/dev/null || echo "  (none)"
else
    echo "❌ Backup failed!"
    exit 1
fi

echo ""
echo "To restore from this backup:"
echo "  cd $STACK_DIR"
echo "  docker-compose down"
echo "  tar -xzf $BACKUP_FILE"
echo "  docker-compose up -d"
