#!/usr/bin/env bash
# backup.sh — back up all container configs and compose files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_FILE="$HOME/media-stack-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

cd "$COMPOSE_DIR"

echo "==> Creating backup: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" \
  sabnzbd/ \
  sonarr/ \
  radarr/ \
  jellyfin/ \
  docker-compose.yml \
  .env 2>/dev/null || true

echo ""
echo "Backup saved to: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"
