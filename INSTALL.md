# Installation Guide

Step-by-step instructions for setting up the media automation stack from scratch.

## Prerequisites

- Ubuntu Server 24.04 LTS (or compatible Linux distribution)
- Minimum 4GB RAM (8GB recommended)
- 100GB+ local storage for downloads
- Network access to NAS with NFS share
- Usenet provider and indexer accounts

## Step-by-Step Installation

### 1. Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker Engine and the Compose V2 plugin
sudo apt install docker.io docker-compose-plugin -y

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and back in, then verify
docker --version
docker compose version
```

> **Note:** This installs Compose V2 (`docker compose`, no hyphen). The old `docker-compose`
> (V1) is end-of-life and not used here.

### 2. Install NFS Client

```bash
sudo apt install nfs-common -y
```

### 3. Clone This Repository

```bash
# Create the target directory first, then clone into it
sudo mkdir -p /opt/media-stack
sudo git clone https://github.com/yourusername/media-stack.git /opt/media-stack
cd /opt/media-stack

# Make scripts executable and set ownership
sudo chmod +x scripts/*.sh
sudo chown -R $USER:$USER /opt/media-stack
```

### 4. Configure Environment Variables

```bash
cp .env.example .env
id $USER        # note your UID and GID
nano .env
```

Update in `.env`:

```
PUID=1000               # Your UID from 'id' command
PGID=1000               # Your GID from 'id' command
TZ=America/New_York     # Your timezone
NAS_IP=YOUR_NAS_IP      # Your NAS IP address
NAS_SHARE_PATH=/mnt/Default_Pool/Media   # Your NFS share path
```

### 5. Configure NFS Mount

```bash
# Open the mount file and replace YOUR_NAS_IP and YOUR_NAS_SHARE_PATH
sudo nano systemd/storage-data-nas-media.mount
```

The `What=` line should look like:
```
What=YOUR_NAS_IP:YOUR_NAS_SHARE_PATH
```

```bash
# Install and enable the mount
sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable storage-data-nas-media.mount
sudo systemctl start storage-data-nas-media.mount

# Verify
systemctl status storage-data-nas-media.mount
mount | grep media
```

You should see your NAS mounted at `/storage/data/nas/media`.

### 6. Create Directory Structure

```bash
sudo ./scripts/setup-directories.sh
```

This creates:
- `/storage/data/local/downloads/incomplete`
- `/storage/data/local/downloads/complete/tv`
- `/storage/data/local/downloads/complete/movies`
- `/storage/data/nas/media` (NFS mount point)

### 7. Configure Docker to Wait for NFS

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload
```

### 8. Start the Docker Stack

```bash
cd /opt/media-stack
docker compose pull
docker compose up -d
docker compose ps
```

All four containers (sabnzbd, sonarr, radarr, jellyfin) should show "Up".

### 9. Access Web Interfaces

Replace `YOUR_SERVER_IP` with your server's IP address (run `ip a` to find it):

- **SABnzbd:** `http://YOUR_SERVER_IP:8080`
- **Sonarr:** `http://YOUR_SERVER_IP:8989`
- **Radarr:** `http://YOUR_SERVER_IP:7878`
- **Jellyfin:** `http://YOUR_SERVER_IP:8096`

### 10. Configure SABnzbd

1. Complete the setup wizard
2. **Config → Servers** — add your Usenet provider (host, port, SSL, credentials, connections)
3. **Config → Folders:**
   - Temporary Download Folder: `/incomplete-downloads`
   - Completed Download Folder: `/downloads/complete`
4. **Config → Categories:**
   - Add **tv** — Folder: `tv`
   - Add **movies** — Folder: `movies`
5. **Config → General** — copy your API Key (needed for Sonarr/Radarr)

### 11. Configure Sonarr

1. **Settings → Media Management → Root Folders** — add `/tv`
2. Toggle **Rename Episodes** ON
3. **Settings → Download Clients** → add SABnzbd:
   - Host: `sabnzbd` (container name, not an IP)
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Category: `tv`
   - Test and Save
4. **Download Clients → Remote Path Mappings** → add:
   - Host: `sabnzbd`
   - Remote Path: `/downloads/complete/`
   - Local Path: `/downloads/complete/`
5. **Settings → Indexers** — add your Usenet indexer

### 12. Configure Radarr

Same as Sonarr, with these differences:
- Root folder: `/movies`
- Toggle **Rename Movies** ON
- SABnzbd category: `movies`
- Same Remote Path Mapping as Sonarr

### 13. Configure Jellyfin

1. Complete the setup wizard and create your admin account
2. **Dashboard → Libraries → Add Media Library:**
   - TV Shows — folder: `/data/tv`
   - Movies — folder: `/data/movies`
3. **Dashboard → Scheduled Tasks → Scan Media Library → Run Now**

## Testing the Setup

1. In Sonarr: **Series → Add New**, search and add a show, manually search an episode and download
2. Watch progress: SABnzbd downloads → Sonarr imports → appears in Jellyfin

```bash
# Watch download folder
watch -n 2 'ls -lh /storage/data/local/downloads/incomplete'

# Check after import
ls -lh /storage/data/nas/media/tv/
```

## Troubleshooting

```bash
# Container logs
docker compose logs -f

# NFS mount
sudo systemctl status storage-data-nas-media.mount
sudo systemctl restart storage-data-nas-media.mount

# Permission errors
sudo chown -R 1000:1000 /storage/data/local/downloads
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.
