#!/usr/bin/env bash
# setup-directories.sh — create required directory structure for the media stack
set -euo pipefail

echo "==> Creating local download directories..."
sudo mkdir -p /storage/data/local/downloads/incomplete
sudo mkdir -p /storage/data/local/downloads/complete/tv
sudo mkdir -p /storage/data/local/downloads/complete/movies

echo "==> Creating NFS mount point..."
sudo mkdir -p /storage/data/nas/media

echo "==> Setting ownership on local download directories..."
sudo chown -R "$USER":"$USER" /storage/data/local/downloads

echo ""
echo "Directory structure created:"
find /storage/data/local/downloads -type d | sort
echo "/storage/data/nas/media  (NFS mount point — will be populated after NFS mount)"

echo ""
echo "Done. Next: configure and enable the NFS systemd mount."
