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

See [docs/BOOT_CONFIGURATION.md](docs/BOOT_CONFIGURATION.md) for details.

## Prerequisites

- Ubuntu Server 24.04 LTS (or similar Linux distro)
- Docker Engine + Docker Compose V2 (`docker-compose-plugin`)
- NAS with NFS share configured
- Usenet provider account (for SABnzbd)
- Minimum 4GB RAM, 8GB recommended
- 100GB+ local storage for downloads

## Quick Start

### 1. Clone this repository

```bash
sudo mkdir -p /opt/media-stack
sudo git clone https://github.com/yourusername/media-stack.git /opt/media-stack
cd /opt/media-stack
sudo chmod +x scripts/*.sh
sudo chown -R $USER:$USER /opt/media-stack
```

### 2. Configure your environment

```bash
cp .env.example .env
nano .env
```

Update `PUID`, `PGID` (run `id $USER`), `TZ`, `NAS_IP`, and `NAS_SHARE_PATH`.

### 3. Set up NFS mount

```bash
# Fill in YOUR_NAS_IP and YOUR_NAS_SHARE_PATH in the mount file
sudo nano systemd/storage-data-nas-media.mount

sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable storage-data-nas-media.mount
sudo systemctl start storage-data-nas-media.mount

# Verify
mount | grep media
```

### 4. Create directory structure

```bash
sudo ./scripts/setup-directories.sh
```

### 5. Configure Docker to wait for NFS

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload
sudo systemctl enable docker
```

### 6. Start the stack

```bash
docker compose up -d
```

### 7. Verify boot configuration

```bash
./scripts/verify-boot-config.sh
```

### 8. Access the web interfaces

Replace `YOUR_SERVER_IP` with your server's IP (run `ip a` to find it):

- **SABnzbd:** `http://YOUR_SERVER_IP:8080`
- **Sonarr:** `http://YOUR_SERVER_IP:8989`
- **Radarr:** `http://YOUR_SERVER_IP:7878`
- **Jellyfin:** `http://YOUR_SERVER_IP:8096`

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

## Maintenance

### Update containers

Always stop before pulling to avoid image compatibility errors:

```bash
cd /opt/media-stack
./scripts/update.sh
```

Or manually:

```bash
docker compose down
docker compose pull
docker compose up -d
```

### View logs

```bash
docker compose logs -f           # all services
docker compose logs -f sabnzbd   # specific service
```

### Restart a service

```bash
docker compose restart sabnzbd
```

### Backup and restore

```bash
# Backup
./scripts/backup.sh

# Restore
cd /opt/media-stack
tar -xzf ~/media-stack-backup-YYYYMMDD-HHMMSS.tar.gz
docker compose down
docker compose up -d
```

## Troubleshooting

```bash
# Check everything
./scripts/verify-boot-config.sh

# Check NFS mount
systemctl status storage-data-nas-media.mount

# Check Docker
sudo systemctl status docker

# Start stack manually
docker compose up -d
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed problem solving.

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed step-by-step installation guide
- **[docs/BOOT_CONFIGURATION.md](docs/BOOT_CONFIGURATION.md)** - Boot and auto-start configuration
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Problem solving
- **[docs/CONFIGURATION_EXAMPLES.md](docs/CONFIGURATION_EXAMPLES.md)** - Advanced configurations

## Scripts

- **`scripts/setup-directories.sh`** - Create required directory structure
- **`scripts/backup.sh`** - Backup all configurations
- **`scripts/update.sh`** - Update all containers (stops first to avoid errors)
- **`scripts/verify-boot-config.sh`** - Verify auto-start configuration

## Security Notes

- Never commit `.env` to git — it contains your credentials
- The `.gitignore` prevents this, but always double-check before pushing
- Ports are bound to all interfaces by default; restrict to your LAN IP if the server is internet-facing
- Keep containers updated regularly with `./scripts/update.sh`
- Consider a reverse proxy (Nginx, Caddy) with HTTPS for external access

## Client Setup

**Jellyfin on Google TV:** Install "Jellyfin for Android TV" from the Play Store.

**Jellyfin on Mobile:** Install from iOS App Store or Google Play.

**Kodi:** Install "Jellyfin for Kodi" from the Kodi repository.

## License

MIT License — see LICENSE file for details.

## Acknowledgments

- [LinuxServer.io](https://www.linuxserver.io/) for excellent Docker images
- [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/), [SABnzbd](https://sabnzbd.org/), [Jellyfin](https://jellyfin.org/) teams
