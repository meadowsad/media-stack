# Boot Configuration Guide

This guide explains how to ensure all services start automatically on system boot.

## Overview

For the media stack to work properly after a reboot, these components must start in the correct order:

1. **Network** comes online
2. **NFS mount** activates
3. **Docker service** starts (after NFS is ready)
4. **Docker containers** auto-start

## Configuration Steps

### 1. Enable Docker Service

Ensure Docker starts on boot:

```bash
sudo systemctl enable docker
sudo systemctl status docker
```

Should show: `enabled`

### 2. Enable NFS Mount

The NFS mount must be enabled to start on boot:

```bash
sudo systemctl enable storage-data-nas-media.mount
sudo systemctl status storage-data-nas-media.mount
```

Should show: `enabled` and `active (mounted)`

### 3. Configure Docker to Wait for NFS

This is critical - Docker must wait for NFS before starting:

```bash
# Create override directory
sudo mkdir -p /etc/systemd/system/docker.service.d

# Copy the override file
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf

# Reload systemd
sudo systemctl daemon-reload

# Restart Docker to apply
sudo systemctl restart docker
```

**Verify it worked:**
```bash
sudo systemctl show docker.service | grep After=
# Should include: storage-data-nas-media.mount
```

### 4. Verify Container Restart Policies

The `docker-compose.yml` file includes `restart: unless-stopped` for all containers. This means:
- Containers auto-start when Docker starts
- Containers restart if they crash
- Containers stay stopped if you manually stop them

**Verify:**
```bash
docker inspect sabnzbd sonarr radarr jellyfin --format '{{.Name}}: {{.HostConfig.RestartPolicy.Name}}'
```

Should show: `unless-stopped` for all containers

## Verification Script

Use the provided script to check everything:

```bash
cd /opt/media-stack
./scripts/verify-boot-config.sh
```

This checks:
- Docker service enabled
- NFS mount enabled and active
- Docker/NFS dependency configured
- Container restart policies
- Directory structure

## Testing Boot Configuration

### Method 1: Safe Test (Restart Docker Only)

```bash
cd /opt/media-stack
docker-compose down
sudo systemctl restart docker
sleep 10
docker-compose ps
```

All containers should be "Up"

### Method 2: Full Reboot Test

```bash
sudo reboot
```

After reboot (wait 1-2 minutes):

```bash
# Check NFS is mounted
mount | grep media

# Check Docker is running
sudo systemctl status docker

# Check containers are running
cd /opt/media-stack
docker-compose ps

# Access web interfaces
# http://your_nas_ip:8080 (SABnzbd)
# http://your_nas_ip:8989 (Sonarr)
# http://your_nas_ip:7878 (Radarr)
# http://your_nas_ip:8096 (Jellyfin)
```

## Boot Sequence Details

### What Happens on Boot

```
1. System Boot
   ↓
2. Network Initialization (network-online.target)
   ↓
3. NFS Mount (storage-data-nas-media.mount)
   - Requires: network-online.target
   - Mounts: your_nas_ip:/path to /storage/data/nas/media
   ↓
4. Docker Service (docker.service)
   - Requires: storage-data-nas-media.mount
   - Waits for NFS before starting
   ↓
5. Docker Containers Auto-Start
   - sabnzbd (restart: unless-stopped)
   - sonarr (restart: unless-stopped)
   - radarr (restart: unless-stopped)
   - jellyfin (restart: unless-stopped)
```

### Why Order Matters

If Docker starts before NFS:
- Containers see empty `/storage/data/nas/media` directory
- Docker creates bind mounts to empty directory
- Even after NFS mounts, containers still see empty directory
- Requires `docker-compose down && docker-compose up -d` to fix

The `wait-for-nfs.conf` override prevents this issue.

## Troubleshooting Boot Issues

### Containers Don't Start After Reboot

**Check Docker service:**
```bash
sudo systemctl status docker
journalctl -u docker -n 50
```

**Check if Docker waited for NFS:**
```bash
systemctl show docker.service | grep After=
# Should include storage-data-nas-media.mount
```

**Manual fix:**
```bash
cd /opt/media-stack
docker-compose up -d
```

### NFS Doesn't Mount on Boot

**Check mount status:**
```bash
systemctl status storage-data-nas-media.mount
journalctl -u storage-data-nas-media.mount -n 50
```

**Common causes:**
- NAS is offline/unreachable
- Network not ready when mount tried
- Incorrect mount configuration

**Manual fix:**
```bash
sudo systemctl start storage-data-nas-media.mount
```

### Containers Start But Can't Access NFS Files

This means Docker started before NFS was ready.

**Fix:**
```bash
cd /opt/media-stack
docker-compose down
# Verify NFS is mounted
mount | grep media
# Restart containers
docker-compose up -d
```

**Prevent:**
Make sure `docker-wait-for-nfs.conf` is properly installed.

### Services Start in Wrong Order

**Check dependency chain:**
```bash
systemctl list-dependencies docker.service
systemctl list-dependencies storage-data-nas-media.mount
```

**Fix:**
```bash
sudo systemctl daemon-reload
sudo reboot
```

## Advanced Configuration

### Change Boot Timeout

If your NFS mount takes a long time:

Edit `/etc/systemd/system/storage-data-nas-media.mount`:
```ini
[Mount]
TimeoutSec=120
# ... rest of config
```

Then:
```bash
sudo systemctl daemon-reload
```

### Add Boot Delay for Docker

If containers start too quickly after NFS:

Create `/etc/systemd/system/docker.service.d/delay.conf`:
```ini
[Service]
ExecStartPre=/bin/sleep 5
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Container-Specific Delays

In `docker-compose.yml`, add health checks to delay dependent services:

```yaml
services:
  sonarr:
    depends_on:
      sabnzbd:
        condition: service_healthy
    # ... rest of config
  
  sabnzbd:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 10s
      timeout: 5s
      retries: 5
    # ... rest of config
```

## Disable Auto-Start (If Needed)

### Disable Specific Container

```bash
docker update --restart=no sabnzbd
```

### Disable All Auto-Start

Edit `docker-compose.yml` and change:
```yaml
restart: unless-stopped
```
to:
```yaml
restart: "no"
```

Then:
```bash
docker-compose down
docker-compose up -d
```

### Disable Docker Service

```bash
sudo systemctl disable docker
```

(Not recommended - you'll need to manually start everything)

## Monitoring Boot Process

### View Boot Logs

```bash
# All services
journalctl -b

# Specific service
journalctl -b -u docker.service
journalctl -b -u storage-data-nas-media.mount

# Follow during boot (from another terminal/SSH session)
journalctl -f
```

### Check Boot Time

```bash
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain docker.service
```

## Best Practices

1. **Always test** boot configuration after changes
2. **Verify** with the verification script regularly
3. **Monitor** first boot after configuration changes
4. **Document** any custom modifications
5. **Backup** systemd override files to git

## Emergency Recovery

If system won't boot properly:

1. Boot into recovery mode or use live USB
2. Check logs: `journalctl -b -1` (previous boot)
3. Disable problematic mounts:
   ```bash
   sudo systemctl mask storage-data-nas-media.mount
   ```
4. Boot normally
5. Fix the issue
6. Re-enable:
   ```bash
   sudo systemctl unmask storage-data-nas-media.mount
   ```

## Summary Checklist

- [ ] Docker service enabled
- [ ] NFS mount enabled
- [ ] Docker wait-for-NFS configured
- [ ] Container restart policies set
- [ ] Directories created
- [ ] Tested with reboot
- [ ] All services accessible after reboot

Run `./scripts/verify-boot-config.sh` to check all items automatically!
