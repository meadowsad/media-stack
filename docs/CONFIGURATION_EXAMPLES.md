# Configuration Examples

This document provides example configurations for various scenarios and setups.

## Alternative NFS Mount Configurations

### NFSv4 Mount
```ini
[Unit]
Description=NAS Media NFS Mount (NFSv4)
Requires=network-online.target
After=network-online.target
Before=docker.service

[Mount]
What=10.0.4.151:/mnt/Default_Pool/Media
Where=/storage/data/nas/media
Type=nfs
Options=rw,hard,nofail,_netdev,vers=4,rsize=1048576,wsize=1048576

[Install]
WantedBy=multi-user.target
```

### Mount with Authentication
```ini
[Mount]
What=10.0.4.151:/mnt/Default_Pool/Media
Where=/storage/data/nas/media
Type=nfs
Options=rw,hard,nofail,_netdev,rsize=1048576,wsize=1048576,sec=sys,timeo=14

[Install]
WantedBy=multi-user.target
```

### Soft Mount (for unstable networks)
```ini
[Mount]
What=10.0.4.151:/mnt/Default_Pool/Media
Where=/storage/data/nas/media
Type=nfs
Options=rw,soft,nofail,_netdev,rsize=1048576,wsize=1048576,timeo=30,retrans=3

[Install]
WantedBy=multi-user.target
```

## Docker Compose Variations

### With Custom Network
```yaml
version: "3.8"

networks:
  media:
    driver: bridge

services:
  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    networks:
      - media
    # ... rest of config

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    networks:
      - media
    # ... rest of config
```

### With Resource Limits
```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '0.5'
          memory: 1G
    # ... rest of config
```

### With Health Checks
```yaml
services:
  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    # ... rest of config
```

### With Logging Configuration
```yaml
services:
  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    # ... rest of config
```

## Environment File Examples

### Minimal .env
```bash
PUID=1000
PGID=1000
TZ=America/New_York
```

### Full .env with All Options
```bash
# User and Group ID
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# NAS Configuration
NAS_IP=10.0.4.151
NAS_SHARE_PATH=/mnt/Default_Pool/Media

# Port Configuration (optional)
SABNZBD_PORT=8080
SONARR_PORT=8989
RADARR_PORT=7878
JELLYFIN_PORT=8096

# Storage Paths (optional)
LOCAL_DOWNLOAD_PATH=/storage/data/local/downloads
NAS_MOUNT_PATH=/storage/data/nas/media
```

## SABnzbd Categories Configuration

### Advanced Categories
In SABnzbd → Config → Categories:

**tv-hd:**
- Priority: High
- Processing: +Delete
- Folder/Path: tv-hd

**tv-4k:**
- Priority: High
- Processing: +Delete
- Folder/Path: tv-4k

**movies-hd:**
- Priority: Normal
- Processing: +Delete
- Folder/Path: movies-hd

**movies-4k:**
- Priority: Normal
- Processing: +Delete
- Folder/Path: movies-4k

## Sonarr/Radarr Quality Profiles

### 1080p Maximum Profile
Create in Sonarr/Radarr → Settings → Profiles → Quality Profiles:

**Name:** 1080p Max
- Allowed: WEBDL-1080p, WEBRip-1080p, Bluray-1080p
- Upgrades allowed: Yes
- Upgrade until: Bluray-1080p

### 4K Profile
**Name:** 4K
- Allowed: WEBDL-2160p, WEBRip-2160p, Bluray-2160p
- Upgrades allowed: Yes
- Upgrade until: Bluray-2160p

## Jellyfin Library Settings

### TV Shows Library - Advanced
- **Enable chapter image extraction:** No (saves CPU)
- **Automatically refresh metadata from the internet:** Every 30 days
- **Save artwork into media folders:** Yes
- **Download images in advance:** Yes

### Movies Library - Advanced
- **Enable chapter image extraction:** Yes (for seeking)
- **Automatically refresh metadata from the internet:** Every 30 days
- **Extract chapter images:** Yes
- **Download images in advance:** Yes

## Alternative Directory Structures

### Separated by Quality
```
/storage/data/nas/media/
├── tv-1080p/
├── tv-4k/
├── movies-1080p/
└── movies-4k/
```

Then in docker-compose.yml:
```yaml
  sonarr:
    volumes:
      - /storage/data/nas/media/tv-1080p:/tv-1080p
      - /storage/data/nas/media/tv-4k:/tv-4k

  radarr:
    volumes:
      - /storage/data/nas/media/movies-1080p:/movies-1080p
      - /storage/data/nas/media/movies-4k:/movies-4k
```

### Everything on NAS
```yaml
services:
  sabnzbd:
    volumes:
      - /storage/data/nas/downloads:/downloads
      - /storage/data/nas/downloads/incomplete:/incomplete-downloads
```

Note: This can be slower if your NAS connection isn't fast enough.

## Cron Jobs for Automation

### Daily Backup
```bash
# Edit crontab
crontab -e

# Add this line (backup at 2 AM daily)
0 2 * * * /opt/media-stack/scripts/backup.sh
```

### Weekly Container Update
```bash
# Update containers every Sunday at 3 AM
0 3 * * 0 /opt/media-stack/scripts/update.sh
```

### Clean Download Directory Weekly
```bash
# Clean completed downloads every Monday at 4 AM
0 4 * * 1 find /storage/data/local/downloads/complete -type f -mtime +7 -delete
```

## Firewall Configurations

### UFW (Ubuntu)
```bash
# Allow only from local network
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8989 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 7878 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8096 proto tcp
```

### Firewalld (Fedora/RHEL)
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8989/tcp
sudo firewall-cmd --permanent --add-port=7878/tcp
sudo firewall-cmd --permanent --add-port=8096/tcp
sudo firewall-cmd --reload
```

## Reverse Proxy Examples

### Nginx with SSL
```nginx
# /etc/nginx/sites-available/media-stack
server {
    listen 443 ssl http2;
    server_name media.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/media.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/media.yourdomain.com/privkey.pem;

    location /jellyfin {
        proxy_pass http://localhost:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /sonarr {
        proxy_pass http://localhost:8989;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /radarr {
        proxy_pass http://localhost:7878;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Traefik Labels
```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.yourdomain.com`)"
      - "traefik.http.routers.jellyfin.entrypoints=websecure"
      - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
```

## Multiple User Support

### Different Download Directories per User
Create in docker-compose.yml:
```yaml
  sabnzbd-user1:
    container_name: sabnzbd-user1
    image: linuxserver/sabnzbd:latest
    ports:
      - "8081:8080"
    volumes:
      - ./sabnzbd-user1:/config
      - /storage/user1/downloads:/downloads

  sabnzbd-user2:
    container_name: sabnzbd-user2
    image: linuxserver/sabnzbd:latest
    ports:
      - "8082:8080"
    volumes:
      - ./sabnzbd-user2:/config
      - /storage/user2/downloads:/downloads
```

## Hardware Acceleration for Jellyfin

### Intel QuickSync
```yaml
  jellyfin:
    image: jellyfin/jellyfin:latest
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - "109"  # render group
```

### NVIDIA GPU
```yaml
  jellyfin:
    image: jellyfin/jellyfin:latest
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

## Monitoring Stack Addition

### Add Prometheus and Grafana
```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/config:/etc/prometheus
      - ./prometheus/data:/prometheus

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana:/var/lib/grafana
    depends_on:
      - prometheus
```
