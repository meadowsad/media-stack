#!/bin/bash

# Media Automation Stack - Directory Setup Script
# This script creates all necessary directories with correct permissions

set -e

echo "====================================="
echo "Media Stack Directory Setup"
echo "====================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./setup-directories.sh"
    exit 1
fi

# Get the actual user (not root when using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_UID=$(id -u $ACTUAL_USER)
ACTUAL_GID=$(id -g $ACTUAL_USER)

echo "Setting up directories for user: $ACTUAL_USER ($ACTUAL_UID:$ACTUAL_GID)"
echo ""

# Create local download directories
echo "Creating local download directories..."
mkdir -p /storage/data/local/downloads/incomplete
mkdir -p /storage/data/local/downloads/complete/tv
mkdir -p /storage/data/local/downloads/complete/movies

# Create NFS mount point
echo "Creating NFS mount point..."
mkdir -p /storage/data/nas/media

# Set ownership and permissions on local directories
echo "Setting ownership and permissions..."
chown -R $ACTUAL_UID:$ACTUAL_GID /storage/data/local/downloads
chmod -R 755 /storage/data/local/downloads

echo ""
echo "✅ Directory structure created successfully!"
echo ""
echo "Directory structure:"
echo "/storage/data/"
echo "├── local/"
echo "│   └── downloads/"
echo "│       ├── incomplete/"
echo "│       └── complete/"
echo "│           ├── tv/"
echo "│           └── movies/"
echo "└── nas/"
echo "    └── media/ (NFS mount point)"
echo ""
echo "Next steps:"
echo "1. Configure NFS mount: sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/"
echo "2. Enable NFS mount: sudo systemctl enable storage-data-nas-media.mount"
echo "3. Start NFS mount: sudo systemctl start storage-data-nas-media.mount"
echo "4. Configure Docker: sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf"
echo "5. Reload systemd: sudo systemctl daemon-reload"
echo "6. Start the stack: docker-compose up -d"
