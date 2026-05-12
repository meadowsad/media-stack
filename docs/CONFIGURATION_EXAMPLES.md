# Configuration Examples

Advanced and alternative configurations for various setups.

## Alternative NFS Mount Configurations

Edit `systemd/storage-data-nas-media.mount` with your preferred options, then reinstall:

```bash
sudo cp systemd/storage-data-nas-media.mount /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart storage-data-nas-media.mount
```

### NFSv4 Mount

```ini
[Unit]
Description=NAS Media NFS Mount (NFSv4)
Requires=network-online.target
After=network-online.target
Before=docker.service

[Mount]
What=YOUR_NAS_IP:YOUR_NAS_SHARE_PATH
Where=/storage/data/nas/media
Type=nfs
Options=rw,hard,nofail,_netdev,vers=4,rsize=1048576,wsize=1048576,noexec,nosuid,nodev

[Install]
WantedBy=multi-user.target
```

### Soft Mount (unstable networks)

```ini
[Mount]
What=YOUR_NAS_IP:YOUR_NAS_SHARE_PATH
Where=/storage/data/nas/media
Type=nfs
Options=rw,soft,nofail,_netdev,rsize=1048576,wsize=1048576,timeo=30,retrans=3,noexec,nosuid,nodev
```

---

## Docker Compose Variations

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

  sonarr:
    depends_on:
      sabnzbd:
        condition: service_healthy
```

### With Log Rotation

```yaml
services:
  sabnzbd:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## Environment File Examples

### Full .env with All Options

```bash
# User / Group IDs
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# NAS
NAS_IP=YOUR_NAS_IP
NAS_SHARE_PATH=/mnt/Default_Pool/Media

# Ports (optional — change if defaults conflict)
SABNZBD_PORT=8080
SONARR_PORT=8989
RADARR_PORT=7878
JELLYFIN_PORT=8096
```

If you use the port variables, update `docker-compose.yml` to reference them:

```yaml
ports:
  - "${SABNZBD_PORT:-8080}:8080"
```

---

## SABnzbd Categories

### Advanced Quality-Based Categories

In SABnzbd → Config → Categories:

| Category | Priority | Folder |
|----------|----------|--------|
| tv-hd    | High     | tv-hd  |
| tv-4k    | High     | tv-4k  |
| movies-hd| Normal   | movies-hd |
| movies-4k| Normal   | movies-4k |

---

## Sonarr/Radarr Quality Profiles

### 1080p Max

Settings → Profiles → Quality Profiles → Add:
- **Allowed:** WEBDL-1080p, WEBRip-1080p, Bluray-1080p
- **Upgrade until:** Bluray-1080p

### 4K

- **Allowed:** WEBDL-2160p, WEBRip-2160p, Bluray-2160p
- **Upgrade until:** Bluray-2160p

---

## Alternative Directory Structures

### Separated by Quality

```
/storage/data/nas/media/
├── tv-1080p/
├── tv-4k/
├── movies-1080p/
└── movies-4k/
```

Update volume mappings in `docker-compose.yml`:

```yaml
sonarr:
  volumes:
    - /storage/data/nas/media/tv-1080p:/tv-1080p
    - /storage/data/nas/media/tv-4k:/tv-4k
```

---

## Cron Jobs for Automation

```bash
crontab -e
```

```cron
# Daily backup at 2 AM
0 2 * * * /opt/media-stack/scripts/backup.sh

# Weekly container update Sunday at 3 AM
0 3 * * 0 /opt/media-stack/scripts/update.sh

# Clean completed downloads older than 7 days, Monday 4 AM
0 4 * * 1 find /storage/data/local/downloads/complete -type f -mtime +7 -delete
```

---

## Firewall Rules

Restrict service ports to your local subnet only:

### UFW (Ubuntu)

```bash
# Replace 192.168.1 with your actual subnet
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8989 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 7878 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8096 proto tcp
```

---

## Reverse Proxy Examples

### Nginx with SSL

```nginx
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

---

## Hardware Acceleration for Jellyfin

### Intel QuickSync

```yaml
jellyfin:
  devices:
    - /dev/dri:/dev/dri
  group_add:
    - "109"   # render group
```

### NVIDIA GPU

```yaml
jellyfin:
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

---

## Monitoring Addition (Prometheus + Grafana)

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/config:/etc/prometheus
      - ./prometheus/data:/prometheus
    networks:
      - media

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - media
```
