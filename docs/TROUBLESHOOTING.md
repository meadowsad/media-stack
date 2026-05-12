# Troubleshooting Guide

## NFS Mount Issues

### Mount Not Working / Not Found

**Symptoms:** `mount | grep media` shows nothing; cannot access `/storage/data/nas/media`

```bash
# Check mount status
systemctl status storage-data-nas-media.mount
journalctl -u storage-data-nas-media.mount -n 50

# Test manual mount
sudo mount -t nfs YOUR_NAS_IP:/your/share/path /storage/data/nas/media

# If manual mount works, restart the systemd unit
sudo systemctl restart storage-data-nas-media.mount
```

**Common causes:** NAS offline; firewall blocking NFS port 2049; wrong share path in mount file; NFS not enabled on NAS.

### Mount Active But Directory is Empty

```bash
sudo systemctl restart storage-data-nas-media.mount

# Check what the NAS is exporting
showmount -e YOUR_NAS_IP
```

### Permission Denied on NFS Mount

Check your NAS export settings (e.g., TrueNAS: Sharing → Unix Shares → edit share → Maproot/Mapall settings).

---

## Docker Container Issues

### Containers Won't Start

```bash
docker compose logs -f sabnzbd
docker compose logs -f sonarr
docker compose logs -f radarr
docker compose logs -f jellyfin
```

**Port already in use:**

```bash
sudo lsof -i :8080   # check what's using the port
# Change the host port in docker-compose.yml if needed
```

**Permission denied on /config:**

```bash
sudo chown -R 1000:1000 /opt/media-stack/sabnzbd
sudo chown -R 1000:1000 /opt/media-stack/sonarr
sudo chown -R 1000:1000 /opt/media-stack/radarr
sudo chown -R 1000:1000 /opt/media-stack/jellyfin
```

### Docker Can't Find Compose File

```bash
cd /opt/media-stack
ls -la docker-compose.yml
```

### Containers Keep Restarting

```bash
docker compose logs -f [container_name]
```

Common causes: missing volume mounts; config errors; insufficient RAM.

---

## Jellyfin Can't See Media Files

### Empty Library Despite Files on NAS

```bash
# Check files exist on host
ls /storage/data/nas/media/tv/

# Check from inside the container
docker exec -it jellyfin ls /data/tv/
```

If host has files but container shows empty, Docker started before NFS was ready:

```bash
cd /opt/media-stack
docker compose down
mount | grep media   # confirm NFS is mounted
docker compose up -d
docker exec -it jellyfin ls -la /data/tv/
```

**Prevent this on reboot:** ensure `docker-wait-for-nfs.conf` is installed (run `./scripts/verify-boot-config.sh`).

### Library Won't Scan

```bash
docker compose restart jellyfin
# Or: Jellyfin Dashboard → Scheduled Tasks → Scan Media Library → Run Now
```

---

## Sonarr/Radarr Import Issues

### "No Files Found Are Eligible for Import"

1. **Remote Path Mapping not set** — Settings → Download Clients → Edit SABnzbd → Remote Path Mappings: Host `sabnzbd`, Remote `/downloads/complete/`, Local `/downloads/complete/`
2. **Show/movie not added** to Sonarr/Radarr yet
3. **File naming** doesn't match: TV needs `Show.Name.S01E01.mkv`-style; movies need `Movie.Name.2024.mkv`-style
4. **Wrong SABnzbd category** — verify download used `tv` or `movies`

### "Path Does Not Appear to Exist Inside Container"

```bash
# Verify volume mapping in docker-compose.yml includes:
#   - /storage/data/local/downloads:/downloads

ls -la /storage/data/local/downloads/complete/
docker exec -it sonarr ls -la /downloads/complete/

docker compose down && docker compose up -d
```

---

## SABnzbd Issues

### Can't Set Folders — "Error Accessing"

```bash
sudo chown -R 1000:1000 /storage/data/local/downloads
sudo chmod -R 755 /storage/data/local/downloads
docker compose restart sabnzbd
```

### Downloads Stuck in Queue

Check SABnzbd → Status → Warnings; verify Usenet server connection, available disk space, and article completion.

---

## Network Issues

### Can't Access Web Interfaces

Replace `YOUR_SERVER_IP` with your server's IP address (run `ip a`):

```bash
# Check containers are up
docker compose ps

# Check firewall (Ubuntu)
sudo ufw status
sudo ufw allow 8080/tcp
sudo ufw allow 8989/tcp
sudo ufw allow 7878/tcp
sudo ufw allow 8096/tcp
```

Interfaces should be at:
- `http://YOUR_SERVER_IP:8080` (SABnzbd)
- `http://YOUR_SERVER_IP:8989` (Sonarr)
- `http://YOUR_SERVER_IP:7878` (Radarr)
- `http://YOUR_SERVER_IP:8096` (Jellyfin)

### Containers Can't Communicate

All containers share the `media` Docker network defined in `docker-compose.yml`. Use the container name (e.g., `sabnzbd`) as the hostname, not an IP address.

```bash
docker network ls
docker network inspect media-stack_media
docker compose restart
```

---

## Permission Issues

### Files Created with Wrong Ownership

```bash
id $USER   # confirm your UID/GID
# Update PUID/PGID in .env to match, then:
docker compose down && docker compose up -d
```

### Can't Write to NFS

```bash
# Test write access from host
touch /storage/data/nas/media/tv/test.txt && rm /storage/data/nas/media/tv/test.txt
```

If that fails, check NFS export permissions on the NAS. You can also try adding squash options to the mount:

```
Options=rw,hard,nofail,_netdev,rsize=1048576,wsize=1048576,timeo=14,retrans=2,noexec,nosuid,nodev,all_squash,anonuid=1000,anongid=1000
```

Then: `sudo systemctl daemon-reload && sudo systemctl restart storage-data-nas-media.mount`

---

## Performance Issues

### Slow Downloads

- SABnzbd → Config → Servers → increase Connections (if your provider allows)
- Check disk I/O: `iostat -x 2`

### Jellyfin Buffering

- Enable hardware acceleration: Dashboard → Playback → Transcoding
- Check server load: `htop`

---

## Update Issues

### ContainerConfig Error on `docker compose up -d`

This happens when images are pulled while old containers are still running. Always stop first:

```bash
docker compose down
docker compose pull
docker compose up -d
# Or just: ./scripts/update.sh
```

### Config Lost After Update

Always backup first:

```bash
./scripts/backup.sh
```

Restore:

```bash
cd /opt/media-stack
tar -xzf ~/media-stack-backup-YYYYMMDD-HHMMSS.tar.gz
docker compose down && docker compose up -d
```

---

## Diagnostic Commands

```bash
# NFS
mount | grep media
systemctl status storage-data-nas-media.mount

# Containers
docker compose ps
docker compose logs --tail=50

# Disk space
df -h

# Permissions
ls -la /storage/data/local/downloads
ls -la /storage/data/nas/media

# NAS connectivity
ping YOUR_NAS_IP
```

### Inspect Inside a Container

```bash
docker exec -it sabnzbd bash
# then: ls -la /downloads, exit
```

---

## Common Quick Fixes

### Full Stack Restart

```bash
cd /opt/media-stack
docker compose down
sudo systemctl restart storage-data-nas-media.mount
sudo systemctl restart docker
docker compose up -d
```

### Reset Everything (Nuclear — backup first!)

```bash
cd /opt/media-stack
./scripts/backup.sh
docker compose down -v
sudo rm -rf sabnzbd/ sonarr/ radarr/ jellyfin/
sudo systemctl restart storage-data-nas-media.mount
docker compose up -d
# Reconfigure all services from scratch
```

### Free Up Disk Space

```bash
df -h
# Remove old completed downloads if needed:
rm -rf /storage/data/local/downloads/complete/*
```
