# Installation Guide

This guide provides step-by-step instructions for setting up the media automation stack from scratch.

## Prerequisites

### System Requirements
- Ubuntu Server 24.04 LTS (or compatible Linux distribution)
- Minimum 4GB RAM (8GB recommended)
- 100GB+ local storage for downloads
- Network access to NAS with NFS share
- Internet connection for Docker images and Usenet access

### Required Accounts
- Usenet provider subscription (for SABnzbd)
- Usenet indexer account (for Sonarr/Radarr)

## Step-by-Step Installation

### 1. Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io docker-compose -y

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
exit
```

After logging back in, verify Docker:
```bash
docker --version
docker-compose --version
```

### 2. Install NFS Client

```bash
sudo apt install nfs-common -y
```

### 3. Clone This Repository

```bash
# Clone to /opt (recommended) or your preferred location
cd /opt
sudo git clone https://github.com/yourusername/media-stack.git
cd media-stack

# Make scripts executable
sudo chmod +x scripts/*.sh

# Change ownership to your user
sudo chown -R $USER:$USER /opt/media-stack
```

### 4. Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Find your UID and GID
id $USER

# Edit the environment file
nano .env
```

Update these values in `.env`:
```bash
PUID=1000          # Your UID from 'id' command
PGID=1000          # Your GID from 'id' command
TZ=America/New_York  # Your timezone
NAS_IP=10.0.4.151    # Your NAS IP address
NAS_SHARE_PATH=/mnt/Default_Pool/Media  # Your NFS share path
```

Save and exit (Ctrl+X, Y, Enter)

### 5. Configure NFS Mount

```bash
# Edit the mount file with your NAS details
nano systemd/storage-data-nas-media.mount
```

Update the `What=` line with your NAS IP and share path:
```ini
What=YOUR_NAS_IP:/your/nfs/share/path
```

Save and exit.

```bash
# Copy mount file to systemd
sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable the mount (starts on boot)
sudo systemctl enable storage-data-nas-media.mount

# Start the mount now
sudo systemctl start storage-data-nas-media.mount

# Verify the mount is active
systemctl status storage-data-nas-media.mount
mount | grep media
```

You should see your NAS mounted at `/storage/data/nas/media`

### 6. Create Directory Structure

```bash
# Run the automated setup script
sudo ./scripts/setup-directories.sh
```

This creates:
- `/storage/data/local/downloads/incomplete` - Temporary downloads
- `/storage/data/local/downloads/complete/tv` - Completed TV downloads
- `/storage/data/local/downloads/complete/movies` - Completed movie downloads
- `/storage/data/nas/media` - NFS mount point

### 7. Configure Docker to Wait for NFS

This ensures Docker starts after the NFS mount is ready:

```bash
# Create Docker service override directory
sudo mkdir -p /etc/systemd/system/docker.service.d

# Copy the override configuration
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf

# Reload systemd
sudo systemctl daemon-reload
```

### 8. Start the Docker Stack

```bash
cd /opt/media-stack

# Pull all Docker images (may take a few minutes)
docker-compose pull

# Start all containers
docker-compose up -d

# Verify all containers are running
docker-compose ps
```

You should see all four containers (sabnzbd, sonarr, radarr, jellyfin) in "Up" state.

### 9. Access Web Interfaces

Open a web browser and navigate to:
- **SABnzbd:** http://YOUR_SERVER_IP:8080
- **Sonarr:** http://YOUR_SERVER_IP:8989
- **Radarr:** http://YOUR_SERVER_IP:7878
- **Jellyfin:** http://YOUR_SERVER_IP:8096

Replace `YOUR_SERVER_IP` with your server's IP address (run `ip a` to find it).

### 10. Configure SABnzbd

1. Complete the setup wizard
2. Add your Usenet provider:
   - Go to Config → Servers
   - Click + to add a server
   - Enter your provider details (host, port, username, password, connections, SSL)
   - Test and save

3. Configure folders:
   - Go to Config → Folders
   - **Temporary Download Folder:** `/incomplete-downloads`
   - **Completed Download Folder:** `/downloads/complete`
   - Save changes

4. Configure categories:
   - Go to Config → Categories
   - Add category: **tv**
     - Folder/Path: `tv`
   - Add category: **movies**
     - Folder/Path: `movies`
   - Save changes

5. Note your API Key:
   - Go to Config → General
   - Copy the API Key (you'll need this for Sonarr/Radarr)

### 11. Configure Sonarr

1. Complete the initial setup wizard

2. Add root folder:
   - Settings → Media Management → Root Folders
   - Click + and enter `/tv`
   - Save

3. Enable file renaming:
   - Settings → Media Management
   - Toggle "Rename Episodes" to ON
   - Save

4. Add download client:
   - Settings → Download Clients
   - Click + and select "SABnzbd"
   - **Name:** SABnzbd
   - **Host:** `sabnzbd` (not your server IP!)
   - **Port:** 8080
   - **API Key:** (paste from SABnzbd)
   - **Category:** tv
   - Test, then Save

5. Configure remote path mapping:
   - Still in Download Clients section
   - Scroll to "Remote Path Mappings"
   - Click + to add mapping
   - **Host:** `sabnzbd`
   - **Remote Path:** `/downloads/complete/`
   - **Local Path:** `/downloads/complete/`
   - Save

6. Add indexer:
   - Settings → Indexers
   - Add your preferred Usenet indexer
   - Configure with your indexer credentials

### 12. Configure Radarr

1. Complete the initial setup wizard

2. Add root folder:
   - Settings → Media Management → Root Folders
   - Click + and enter `/movies`
   - Save

3. Enable file renaming:
   - Settings → Media Management
   - Toggle "Rename Movies" to ON
   - Save

4. Add download client:
   - Settings → Download Clients
   - Click + and select "SABnzbd"
   - **Name:** SABnzbd
   - **Host:** `sabnzbd`
   - **Port:** 8080
   - **API Key:** (same as Sonarr)
   - **Category:** movies
   - Test, then Save

5. Configure remote path mapping:
   - Still in Download Clients section
   - Scroll to "Remote Path Mappings"
   - Click + to add mapping
   - **Host:** `sabnzbd`
   - **Remote Path:** `/downloads/complete/`
   - **Local Path:** `/downloads/complete/`
   - Save

6. Add indexer:
   - Settings → Indexers
   - Add your preferred Usenet indexer (same as Sonarr)

### 13. Configure Jellyfin

1. Complete the initial setup wizard
2. Create your admin account

3. Add TV Shows library:
   - Dashboard → Libraries → Add Media Library
   - Content type: **Shows**
   - Display name: **TV Shows**
   - Click + under Folders
   - Enter `/data/tv`
   - Click OK
   - Click OK to save library

4. Add Movies library:
   - Dashboard → Libraries → Add Media Library
   - Content type: **Movies**
   - Display name: **Movies**
   - Click + under Folders
   - Enter `/data/movies`
   - Click OK
   - Click OK to save library

5. Scan for media:
   - Dashboard → Scheduled Tasks
   - Find "Scan Media Library"
   - Click "Run Now"

## Testing the Setup

### Test Download Flow

1. In Sonarr, add a TV show:
   - Series → Add New
   - Search for a show
   - Select it, choose your root folder (`/tv`)
   - Monitor episodes
   - Add Series

2. Manually search for an episode:
   - Click on the show
   - Find an episode
   - Click the magnifying glass icon to search
   - Select a release
   - Click download icon

3. Monitor the download:
   - Activity → Queue shows the download progress
   - SABnzbd shows it downloading to `/incomplete-downloads`
   - When complete, SABnzbd moves it to `/downloads/complete/tv/`
   - Sonarr imports and moves it to `/tv/` on the NAS
   - Jellyfin will detect it on next scan

### Verify File Flow

```bash
# Watch the download process
watch -n 2 'ls -lh /storage/data/local/downloads/incomplete'

# After completion, check complete folder
ls -lh /storage/data/local/downloads/complete/tv/

# After import, check NAS
ls -lh /storage/data/nas/media/tv/YourShowName/
```

## Troubleshooting

### Containers won't start
```bash
docker-compose logs -f
```

### NFS mount not working
```bash
sudo systemctl status storage-data-nas-media.mount
sudo systemctl restart storage-data-nas-media.mount
```

### Permission errors
```bash
sudo chown -R 1000:1000 /storage/data/local/downloads
```

### Import fails in Sonarr/Radarr
- Check Remote Path Mappings are configured correctly
- Verify download client connection
- Check System → Status for warnings

## Next Steps

- Add more TV shows and movies to Sonarr/Radarr
- Configure Jellyfin on your TV or mobile devices
- Set up automated library scans in Jellyfin
- Configure backup routine for configs
- Consider adding authentication/reverse proxy for external access

## Support

For issues, check the troubleshooting section in README.md or open an issue on GitHub.
