#!/usr/bin/env bash
# update.sh — stop, pull latest images, and restart the stack
# Always stops containers before pulling to avoid the ContainerConfig error.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$COMPOSE_DIR"

echo "==> Stopping containers..."
docker compose down

echo "==> Pulling latest images..."
docker compose pull

echo "==> Starting containers..."
docker compose up -d

echo "==> Current status:"
docker compose ps

echo ""
echo "Update complete."
