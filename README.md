# Media Automation Stack

A complete Docker-based media automation system for downloading, organizing, and streaming TV shows and movies using Usenet. **Fully configured for automatic startup on boot.**

## Stack Components

- **SABnzbd** - Usenet downloader
- **Sonarr** - TV show automation and management
- **Radarr** - Movie automation and management
- **Jellyfin** - Media server for streaming to any device

## Features

- ✅ Automated TV show and movie downloads
- ✅ Local temporary storage with NFS final destination
- ✅ Proper file organization and renaming
- ✅ Universal streaming via Jellyfin
- ✅ Works with Kodi, web browsers, and mobile apps
- ✅ **Auto-starts on system boot** with correct service ordering

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Sonarr/Radarr monitor for new content                    │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. SABnzbd downloads to local storage (/incomplete)         │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. SABnzbd completes to local storage (/complete)           │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Sonarr/Radarr import and MOVE files to NAS via NFS       │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Jellyfin serves content from NAS to all devices          │
└─────────────────────────────────────────────────────────────┘
```

## Boot Sequence (Automatic)

```
System Boot → Network Ready → NFS Mount → Docker Service → All Containers
```

The system is configured to start everything in the correct order automatically. See [BOOT_CONFIGURATION.md](docs/BOOT_CONFIGURATION.md) for details.

## Prerequisites

- Ubuntu Server 24.04 LTS (or similar Linux distro)
- Docker and Docker Compose installed
- NAS with NFS share configured
- Usenet provider account (for SABnzbd)
- Minimum 4GB RAM, 8GB recommended
- Local storage for downloads (100GB+ recommended)

## Quick Start

### 1. Clone this repository

```bash
git clone https://github.com/yourusername/media-stack.git
cd media-stack
```

### 2. Configure your environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your settings
nano .env
```

Update these variables:
- `PUID` and `PGID` (run `id $USER` to find yours)
- `TZ` (your timezone, e.g., America/New_York)
- `NAS_IP` (your NAS IP address)
- `NAS_SHARE_PATH` (path to your NFS share)

### 3. Set up NFS mount

```bash
# Update the mount file with your NAS details
sudo nano systemd/storage-data-nas-media.mount

# Copy to systemd directory
sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/

# Enable and start the mount
sudo systemctl daemon-reload
sudo systemctl enable storage-data-nas-media.mount
sudo systemctl start storage-data-nas-media.mount

# Verify it's working
mount | grep media
```

### 4. Create directory structure

```bash
# Run the setup script
sudo ./scripts/setup-directories.sh
```

Or manually:
```bash
sudo mkdir -p /storage/data/local/downloads/{incomplete,complete/{tv,movies}}
sudo mkdir -p /storage/data/nas/media
sudo chown -R $USER:$USER /storage/data/local/downloads
```

### 5. Configure Docker to wait for NFS

**This step is critical for auto-start on boot:**

```bash
# Ensure Docker starts after NFS mount
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload

# Enable Docker to start on boot
sudo systemctl enable docker
```

### 6. Start the stack

```bash
docker-compose up -d
```

### 7. Verify boot configuration

```bash
# Run the verification script
./scripts/verify-boot-config.sh
```

This checks that everything is properly configured to auto-start.

### 8. Access the web interfaces

- **SABnzbd:** http://your-server-ip:8080
- **Sonarr:** http://your-server-ip:8989
- **Radarr:** http://your-server-ip:7878
- **Jellyfin:** http://your-server-ip:8096

## Configuration Guide

See [INSTALL.md](INSTALL.md) for detailed setup instructions for each service.

## Directory Structure

```
/storage/data/
├── local/
│   └── downloads/
│       ├── incomplete/          # SABnzbd temp downloads
│       └── complete/
│           ├── tv/              # Completed TV downloads
│           └── movies/          # Completed movie downloads
└── nas/
    └── media/                   # NFS mount from NAS
        ├── tv/                  # Final TV storage
        └── movies/              # Final movie storage

/opt/media-stack/
├── docker-compose.yml
├── .env
├── sabnzbd/                     # SABnzbd config (auto-created)
├── sonarr/                      # Sonarr config (auto-created)
├── radarr/                      # Radarr config (auto-created)
└── jellyfin/                    # Jellyfin config (auto-created)
```

## Automatic Startup

The system is configured to start automatically on boot with proper service ordering:

1. **NFS mount** activates when network is ready
2. **Docker service** waits for NFS before starting  
3. **All containers** auto-start with `restart: unless-stopped`

**To verify auto-start configuration:**
```bash
./scripts/verify-boot-config.sh
```

**To test:**
```bash
sudo reboot
# Wait 1-2 minutes, then check:
docker-compose ps
```

See [BOOT_CONFIGURATION.md](docs/BOOT_CONFIGURATION.md) for complete details.

## Maintenance

### Update containers

```bash
cd /opt/media-stack
./scripts/update.sh
```

Or manually:
```bash
docker-compose pull
docker-compose up -d
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f sabnzbd
```

### Restart a service

```bash
docker-compose restart sabnzbd
```

### Backup configuration

```bash
./scripts/backup.sh
```

Or manually:
```bash
cd /opt/media-stack
tar -czf ~/media-stack-backup-$(date +%Y%m%d).tar.gz \
  sabnzbd/ sonarr/ radarr/ jellyfin/ docker-compose.yml .env
```

### Restore from backup

```bash
cd /opt/media-stack
tar -xzf ~/media-stack-backup-YYYYMMDD.tar.gz
docker-compose down
docker-compose up -d
```

## Troubleshooting

### Services don't start after reboot

```bash
# Check boot configuration
./scripts/verify-boot-config.sh

# Check NFS mount
systemctl status storage-data-nas-media.mount

# Check Docker service
sudo systemctl status docker

# Manually start if needed
docker-compose up -d
```

For more issues, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[docs/BOOT_CONFIGURATION.md](docs/BOOT_CONFIGURATION.md)** - Boot and auto-start configuration
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Problem solving
- **[docs/CONFIGURATION_EXAMPLES.md](docs/CONFIGURATION_EXAMPLES.md)** - Advanced configurations
- **[GITHUB_GUIDE.md](GITHUB_GUIDE.md)** - Using this repo with GitHub

## Scripts

- **`scripts/setup-directories.sh`** - Create required directory structure
- **`scripts/backup.sh`** - Backup all configurations
- **`scripts/update.sh`** - Update all containers
- **`scripts/verify-boot-config.sh`** - Verify auto-start configuration

## Security Notes

- Never commit `.env` file with real credentials to git
- Change default ports if exposing to internet
- Consider using a reverse proxy with HTTPS
- Keep containers updated regularly

## Client Setup

### Jellyfin on Google TV

Install "Jellyfin for Android TV" from the Play Store and enter your server address.

### Jellyfin on Mobile

Install the Jellyfin app from iOS App Store or Google Play Store.

### Kodi Integration

Install "Jellyfin for Kodi" add-on from the Kodi repository.

## Contributing

Feel free to open issues or submit pull requests for improvements!

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [LinuxServer.io](https://www.linuxserver.io/) for excellent Docker images
- [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/), [SABnzbd](https://sabnzbd.org/), and [Jellyfin](https://jellyfin.org/) teams
