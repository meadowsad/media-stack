# Troubleshooting Guide

This guide covers common issues and their solutions.

## NFS Mount Issues

### Mount Not Working / Not Found

**Symptoms:**
- `mount | grep media` shows nothing
- Cannot access `/storage/data/nas/media`

**Solutions:**

```bash
# Check mount status
systemctl status storage-data-nas-media.mount

# Check for errors in logs
journalctl -u storage-data-nas-media.mount -n 50

# Try manual mount to test
sudo mount -t nfs your_nas_ip:/mnt/Default_Pool/Media /storage/data/nas/media

# If manual mount works, restart systemd mount
sudo systemctl restart storage-data-nas-media.mount
```

**Common Causes:**
- NAS is offline or unreachable
- Firewall blocking NFS ports (2049)
- Incorrect NFS share path in mount file
- NFS not enabled on NAS

### Mount Shows as Active But Directory is Empty

**Symptoms:**
- `systemctl status storage-data-nas-media.mount` shows active
- `ls /storage/data/nas/media` shows empty directory

**Solution:**

```bash
# Restart the mount
sudo systemctl restart storage-data-nas-media.mount

# If still empty, check NFS server exports
showmount -e YOUR_NAS_IP

# Verify the share path is correct
```

### Permission Denied on NFS Mount

**Symptoms:**
- Cannot write to `/storage/data/nas/media`
- Permission denied errors

**Solution:**

Check NFS export options on your NAS. The share should allow read/write access for your network/IP.

For TrueNAS:
1. Sharing → Unix Shares (NFS)
2. Edit your share
3. Check Maproot/Mapall settings
4. Ensure network access is allowed

## Docker Container Issues

### Containers Won't Start

**Check container logs:**
```bash
docker-compose logs -f sabnzbd
docker-compose logs -f sonarr
docker-compose logs -f radarr
docker-compose logs -f jellyfin
```

**Common issues:**

#### Port Already in Use
```
Error: bind: address already in use
```

**Solution:**
```bash
# Check what's using the port
sudo lsof -i :8080  # or whatever port is mentioned

# Stop the conflicting service or change port in docker-compose.yml
```

#### Permission Denied Errors
```
Permission denied: '/config'
```

**Solution:**
```bash
# Fix ownership of config directories
sudo chown -R 1000:1000 /opt/media-stack/sabnzbd
sudo chown -R 1000:1000 /opt/media-stack/sonarr
sudo chown -R 1000:1000 /opt/media-stack/radarr
sudo chown -R 1000:1000 /opt/media-stack/jellyfin
```

### Docker Can't Find Compose File

**Symptom:**
```
Can't find a suitable configuration file
```

**Solution:**
```bash
# Make sure you're in the right directory
cd /opt/media-stack

# Verify docker-compose.yml exists
ls -la docker-compose.yml
```

### Containers Keep Restarting

**Check logs for the specific container:**
```bash
docker-compose logs -f [container_name]
```

**Common causes:**
- Missing volume mounts
- Configuration errors
- Insufficient resources (RAM/CPU)

## Jellyfin Can't See Media Files

### Empty Library Despite Files on NAS

**Symptom:**
- Files exist on NAS: `ls /storage/data/nas/media/tv/` shows content
- Jellyfin shows empty: `docker exec -it jellyfin ls /data/tv/` shows nothing

**Solutions:**

1. **Recreate container with fresh mount:**
```bash
cd /opt/media-stack
docker-compose down
# Verify NFS is mounted
mount | grep media
# Recreate containers
docker-compose up -d
# Check again
docker exec -it jellyfin ls -la /data/tv/
```

2. **Ensure Docker waits for NFS:**
```bash
# Verify override is in place
cat /etc/systemd/system/docker.service.d/wait-for-nfs.conf

# If not present, create it
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf
sudo systemctl daemon-reload
sudo systemctl restart docker
cd /opt/media-stack
docker-compose up -d
```

3. **Check mount happened before Docker started:**
```bash
# Check service startup order
systemctl list-dependencies docker.service
```

### Jellyfin Library Won't Scan

**Solution:**
```bash
# Force a library scan
# In Jellyfin web UI: Dashboard → Scheduled Tasks → Scan Media Library → Run Now

# Or restart Jellyfin to trigger a scan
docker-compose restart jellyfin
```

## Sonarr/Radarr Import Issues

### "No Files Found Are Eligible for Import"

**Symptoms:**
- Files downloaded successfully to `/downloads/complete/tv` or `/movies`
- Sonarr/Radarr can't import them

**Causes and Solutions:**

#### 1. Remote Path Mapping Not Configured
```bash
# In Sonarr/Radarr → Settings → Download Clients → Edit SABnzbd
# Add Remote Path Mapping:
# Host: sabnzbd
# Remote Path: /downloads/complete/
# Local Path: /downloads/complete/
```

#### 2. Series/Movie Not in Sonarr/Radarr
The show/movie must be added to Sonarr/Radarr before it can import files.

#### 3. File Naming Doesn't Match
Files must follow a recognizable naming pattern:
- TV: `Show.Name.S01E01.episode.title.mkv`
- Movies: `Movie.Name.2024.1080p.mkv`

#### 4. Wrong Category in SABnzbd
Verify the download used the correct category (tv/movies).

### "Path Does Not Appear to Exist Inside Container"

**Symptom:**
```
You are using docker; download client SABnzbd places downloads in 
/downloads/complete/movies but this directory does not appear to exist 
inside the container.
```

**Solution:**

1. Verify volume mapping in docker-compose.yml:
```yaml
volumes:
  - /storage/data/local/downloads:/downloads
```

2. Check directory exists:
```bash
ls -la /storage/data/local/downloads/complete/
```

3. Restart containers:
```bash
docker-compose down
docker-compose up -d
```

4. Verify from inside container:
```bash
docker exec -it sonarr ls -la /downloads/complete/
```

## SABnzbd Issues

### Can't Set Folders - "Error Accessing"

**Symptom:**
Permission errors when setting Temporary or Completed download folders.

**Solution:**
```bash
# Fix permissions on download directories
sudo chown -R 1000:1000 /storage/data/local/downloads
sudo chmod -R 755 /storage/data/local/downloads

# Restart SABnzbd
docker-compose restart sabnzbd
```

### Downloads Stuck in Queue

**Check:**
1. SABnzbd → Status → Warnings (bottom of page)
2. Usenet server connection
3. Available disk space
4. Article completion (some downloads are incomplete on servers)

## Network Issues

### Can't Access Web Interfaces

**Symptoms:**
- Cannot reach http://server-ip:8080 (or other ports)

**Solutions:**

1. **Check containers are running:**
```bash
docker-compose ps
# All should show "Up"
```

2. **Check firewall:**
```bash
# Ubuntu firewall
sudo ufw status
# If active and blocking, allow ports
sudo ufw allow 8080/tcp
sudo ufw allow 8989/tcp
sudo ufw allow 7878/tcp
sudo ufw allow 8096/tcp
```

3. **Verify correct IP:**
```bash
ip a
# Use the IP from your network interface (not 127.0.0.1)
```

### Containers Can't Communicate

**Symptom:**
Sonarr/Radarr can't connect to SABnzbd with host `sabnzbd`.

**Solution:**
All containers in the same docker-compose file are on the same network by default. If having issues:

```bash
# Check Docker network
docker network ls
docker network inspect media-stack_default

# Restart all containers
docker-compose restart
```

## Permission Issues

### Files Created with Wrong Ownership

**Symptom:**
Downloaded files owned by root or wrong user.

**Solution:**

Verify PUID/PGID in docker-compose.yml or .env match your user:
```bash
# Check your IDs
id $USER

# Update .env or docker-compose.yml
PUID=1000
PGID=1000

# Recreate containers
docker-compose down
docker-compose up -d
```

### Can't Write to NFS

**Symptom:**
Sonarr/Radarr can't move files to `/tv` or `/movies`.

**Solution:**

1. **Test write access from host:**
```bash
touch /storage/data/nas/media/tv/test.txt
rm /storage/data/nas/media/tv/test.txt
```

2. **If that fails, check NFS export settings on NAS**

3. **Try adding all_squash to mount options:**
Edit `/etc/systemd/system/storage-data-nas-media.mount`:
```ini
Options=rw,hard,nofail,_netdev,rsize=1048576,wsize=1048576,timeo=14,retrans=2,all_squash,anonuid=1000,anongid=1000
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart storage-data-nas-media.mount
```

## Performance Issues

### Slow Downloads

1. **Check Usenet server connections in SABnzbd:**
   - Config → Servers → Connections (increase if your provider allows)

2. **Check network speed:**
```bash
# Install speedtest
sudo apt install speedtest-cli
speedtest-cli
```

3. **Check disk I/O:**
```bash
iostat -x 2
```

### Jellyfin Buffering/Stuttering

1. **Check transcoding settings:**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration may help

2. **Check network between client and server**

3. **Check server resources:**
```bash
htop  # or top
```

## Update Issues

### Failed to Pull Images

**Symptom:**
```
Error response from daemon: pull access denied
```

**Solution:**
```bash
# Ensure Docker service is running
sudo systemctl status docker

# Try pull again
docker-compose pull
```

### Config Lost After Update

**Prevention:**
Always backup before updating:
```bash
cd /opt/media-stack
tar -czf ~/media-stack-backup-$(date +%Y%m%d).tar.gz \
  sabnzbd/ sonarr/ radarr/ jellyfin/ docker-compose.yml .env
```

**Recovery:**
```bash
cd /opt/media-stack
tar -xzf ~/media-stack-backup-YYYYMMDD.tar.gz
docker-compose down
docker-compose up -d
```

## Diagnostic Commands

### Check Everything is Working

```bash
# NFS mount
mount | grep media
systemctl status storage-data-nas-media.mount

# Docker containers
docker-compose ps

# Container logs
docker-compose logs --tail=50

# Disk space
df -h

# Permissions
ls -la /storage/data/local/downloads
ls -la /storage/data/nas/media

# Network connectivity
ping YOUR_NAS_IP
```

### View Inside Containers

```bash
# Enter a container
docker exec -it sabnzbd bash
docker exec -it sonarr bash
docker exec -it radarr bash
docker exec -it jellyfin bash

# Once inside, you can run commands like:
ls -la /downloads
ls -la /tv
pwd
whoami
# Exit with: exit
```

## Getting Help

If you've tried everything and still have issues:

1. **Gather information:**
```bash
# System info
uname -a
docker --version
docker-compose --version

# Check logs
docker-compose logs > ~/docker-logs.txt

# Mount status
mount | grep media > ~/mount-status.txt
```

2. **Check existing issues on GitHub**

3. **Open a new issue with:**
   - Description of the problem
   - Steps to reproduce
   - Relevant logs
   - System information

## Common Quick Fixes

### Full System Restart
```bash
cd /opt/media-stack
docker-compose down
sudo systemctl restart storage-data-nas-media.mount
sudo systemctl restart docker
docker-compose up -d
```

### Reset Everything (Nuclear Option)
```bash
# BACKUP FIRST!
cd /opt/media-stack
docker-compose down -v
sudo rm -rf sabnzbd/ sonarr/ radarr/ jellyfin/
sudo systemctl restart storage-data-nas-media.mount
docker-compose up -d
# Reconfigure all services from scratch
```

### Check Disk Space
```bash
df -h
# If /storage is full, clean up:
rm -rf /storage/data/local/downloads/complete/*
```
