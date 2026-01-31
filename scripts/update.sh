#!/bin/bash

# Media Automation Stack - Update Script
# Updates all Docker containers to the latest versions

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STACK_DIR="$(dirname "$SCRIPT_DIR")"

echo "====================================="
echo "Media Stack Update"
echo "====================================="
echo ""

cd "$STACK_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found in $STACK_DIR"
    exit 1
fi

# Create automatic backup before update
echo "Creating backup before update..."
if [ -f "$SCRIPT_DIR/backup.sh" ]; then
    bash "$SCRIPT_DIR/backup.sh"
    echo ""
else
    echo "⚠️  Warning: backup script not found, skipping backup"
    echo ""
fi

# Pull latest images
echo "Pulling latest Docker images..."
docker-compose pull

echo ""
echo "Recreating containers with new images..."
docker-compose up -d

echo ""
echo "Waiting for containers to start..."
sleep 5

# Show status
echo ""
echo "Container status:"
docker-compose ps

echo ""
echo "✅ Update complete!"
echo ""
echo "Check logs with: docker-compose logs -f"
echo ""
echo "If you encounter issues, restore from backup:"
echo "  cd $STACK_DIR"
echo "  docker-compose down"
echo "  tar -xzf ~/media-stack-backups/media-stack-backup-TIMESTAMP.tar.gz"
echo "  docker-compose up -d"
