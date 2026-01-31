# Media Automation Stack

A complete Docker-based media automation system for downloading, organizing, and streaming TV shows and movies using Usenet.

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
- ✅ Docker-based for easy deployment and updates

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

```bash
# Ensure Docker starts after NFS mount
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload
```

### 6. Start the stack

```bash
docker-compose up -d
```

### 7. Access the web interfaces

- **SABnzbd:** http://your-server-ip:8080
- **Sonarr:** http://your-server-ip:8989
- **Radarr:** http://your-server-ip:7878
- **Jellyfin:** http://your-server-ip:8096

## Configuration Guide

### SABnzbd Setup

1. Complete the initial setup wizard
2. Add your Usenet provider
3. **Folders:**
   - Temporary Download Folder: `/incomplete-downloads`
   - Completed Download Folder: `/downloads/complete`
4. **Categories:**
   - Create `tv` category (folder: `tv`)
   - Create `movies` category (folder: `movies`)
5. Copy the API Key from Config → General

### Sonarr Setup

1. **Settings → Media Management:**
   - Enable "Rename Episodes"
   - Add Root Folder: `/tv`
2. **Settings → Download Clients:**
   - Add SABnzbd
   - Host: `sabnzbd`
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Category: `tv`
3. **Remote Path Mappings:**
   - Host: `sabnzbd`
   - Remote Path: `/downloads/complete/`
   - Local Path: `/downloads/complete/`

### Radarr Setup

1. **Settings → Media Management:**
   - Enable "Rename Movies"
   - Add Root Folder: `/movies`
2. **Settings → Download Clients:**
   - Add SABnzbd
   - Host: `sabnzbd`
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Category: `movies`
3. **Remote Path Mappings:**
   - Host: `sabnzbd`
   - Remote Path: `/downloads/complete/`
   - Local Path: `/downloads/complete/`

### Jellyfin Setup

1. Complete the initial setup wizard
2. **Add Media Libraries:**
   - **TV Shows:** Content type: Shows, Folder: `/data/tv`
   - **Movies:** Content type: Movies, Folder: `/data/movies`
3. Scan libraries to detect existing content

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

```bash
cd /opt/media-stack
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

### NFS mount not working

```bash
# Check mount status
systemctl status storage-data-nas-media.mount

# Check if mounted
mount | grep media

# Restart mount
sudo systemctl restart storage-data-nas-media.mount
```

### Containers can't see NFS files

```bash
# Ensure Docker waits for NFS
sudo systemctl daemon-reload
docker-compose down
sudo systemctl restart docker
docker-compose up -d
```

### Permission errors

```bash
# Fix local download directory permissions
sudo chown -R 1000:1000 /storage/data/local/downloads
sudo chmod -R 755 /storage/data/local/downloads
```

### Sonarr/Radarr can't import files

1. Check Remote Path Mappings are configured correctly
2. Verify download client connection
3. Check System → Status for warnings
4. Try Manual Import from Activity → Queue

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
