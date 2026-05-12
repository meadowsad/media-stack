# Boot Configuration Guide

This guide explains how all services start automatically on boot in the correct order.

## Overview

For the media stack to work properly after a reboot:

1. **Network** comes online
2. **NFS mount** activates
3. **Docker service** starts (after NFS is ready)
4. **Docker containers** auto-start

## Configuration Steps

### 1. Enable Docker Service

```bash
sudo systemctl enable docker
sudo systemctl status docker   # should show: enabled
```

### 2. Enable NFS Mount

```bash
sudo systemctl enable storage-data-nas-media.mount
sudo systemctl status storage-data-nas-media.mount   # should show: enabled, active (mounted)
```

### 3. Configure Docker to Wait for NFS

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload
sudo systemctl restart docker
```

**Verify:**

```bash
sudo systemctl show docker.service | grep After=
# Should include: storage-data-nas-media.mount
```

### 4. Verify Container Restart Policies

All containers in `docker-compose.yml` use `restart: unless-stopped`, meaning they:
- Auto-start when Docker starts
- Restart automatically if they crash
- Stay stopped only if you manually stopped them

```bash
docker inspect sabnzbd sonarr radarr jellyfin \
  --format '{{.Name}}: {{.HostConfig.RestartPolicy.Name}}'
# All should show: unless-stopped
```

## Verification Script

```bash
cd /opt/media-stack
./scripts/verify-boot-config.sh
```

## Testing Boot Configuration

### Method 1: Safe Test (Restart Docker Only)

```bash
cd /opt/media-stack
docker compose down
sudo systemctl restart docker
sleep 10
docker compose ps   # all containers should be "Up"
```

### Method 2: Full Reboot Test

```bash
sudo reboot
```

After reboot (wait 1–2 minutes), verify with `YOUR_SERVER_IP` being your server's IP address:

```bash
mount | grep media                  # NFS mounted
sudo systemctl status docker        # Docker running
docker compose ps                   # containers up

# Access web interfaces at:
# http://YOUR_SERVER_IP:8080  (SABnzbd)
# http://YOUR_SERVER_IP:8989  (Sonarr)
# http://YOUR_SERVER_IP:7878  (Radarr)
# http://YOUR_SERVER_IP:8096  (Jellyfin)
```

## Boot Sequence Details

```
1. System Boot
   ↓
2. Network (network-online.target)
   ↓
3. NFS Mount (storage-data-nas-media.mount)
      Requires: network-online.target
      Mounts: YOUR_NAS_IP:/path → /storage/data/nas/media
   ↓
4. Docker Service (docker.service)
      Requires: storage-data-nas-media.mount
   ↓
5. Containers Auto-Start
      sabnzbd, sonarr, radarr, jellyfin (restart: unless-stopped)
```

### Why Order Matters

If Docker starts before NFS, containers bind-mount to an empty directory. Even after NFS mounts, the containers still see the empty state and require a manual `docker compose down && docker compose up -d` to fix. The `wait-for-nfs.conf` prevents this.

## Troubleshooting Boot Issues

### Containers Don't Start After Reboot

```bash
sudo systemctl status docker
journalctl -u docker -n 50
systemctl show docker.service | grep After=   # should include NFS mount

# Manual fix
cd /opt/media-stack && docker compose up -d
```

### NFS Doesn't Mount on Boot

```bash
systemctl status storage-data-nas-media.mount
journalctl -u storage-data-nas-media.mount -n 50

# Manual fix
sudo systemctl start storage-data-nas-media.mount
```

### Containers Start But Can't Access NFS Files

Docker started before NFS was ready. Fix:

```bash
cd /opt/media-stack
docker compose down
mount | grep media   # confirm NFS is now mounted
docker compose up -d
```

Prevent recurrence: confirm `docker-wait-for-nfs.conf` is installed.

## Advanced Configuration

### Increase Mount Timeout

If your NAS is slow to respond, edit `/etc/systemd/system/storage-data-nas-media.mount`:

```ini
[Mount]
TimeoutSec=120
```

Then: `sudo systemctl daemon-reload`

### Health Check Dependencies

Add health checks in `docker-compose.yml` so Sonarr/Radarr wait for SABnzbd to be ready:

```yaml
services:
  sabnzbd:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 10s
      timeout: 5s
      retries: 5

  sonarr:
    depends_on:
      sabnzbd:
        condition: service_healthy
```

## Monitoring Boot

```bash
# All services from this boot
journalctl -b

# Specific service
journalctl -b -u docker.service
journalctl -b -u storage-data-nas-media.mount

# Boot time analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain docker.service
```

## Emergency Recovery

If the system won't boot correctly:

```bash
# Disable the problematic mount temporarily
sudo systemctl mask storage-data-nas-media.mount
# Boot normally, fix the issue, then re-enable:
sudo systemctl unmask storage-data-nas-media.mount
```

## Summary Checklist

- [ ] Docker service enabled (`sudo systemctl enable docker`)
- [ ] NFS mount enabled (`sudo systemctl enable storage-data-nas-media.mount`)
- [ ] Docker NFS wait configured (`wait-for-nfs.conf` in place)
- [ ] Container restart policies set to `unless-stopped`
- [ ] Directories created (`./scripts/setup-directories.sh`)
- [ ] Tested with reboot — all services accessible after restart

Run `./scripts/verify-boot-config.sh` to check all items automatically.
