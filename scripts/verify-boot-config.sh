#!/bin/bash

# Media Automation Stack - Boot Configuration Verification Script
# Checks if all components are properly configured to start on boot

set -e

echo "=============================================="
echo "Media Stack Boot Configuration Verification"
echo "=============================================="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check 1: Docker service enabled
echo "Checking Docker service..."
if systemctl is-enabled docker &>/dev/null; then
    print_ok "Docker service is enabled (will start on boot)"
else
    print_error "Docker service is NOT enabled"
    echo "   Fix: sudo systemctl enable docker"
fi
echo ""

# Check 2: NFS mount enabled
echo "Checking NFS mount..."
if systemctl is-enabled storage-data-nas-media.mount &>/dev/null; then
    print_ok "NFS mount is enabled (will mount on boot)"
else
    print_error "NFS mount is NOT enabled"
    echo "   Fix: sudo systemctl enable storage-data-nas-media.mount"
fi
echo ""

# Check 3: NFS mount currently active
echo "Checking NFS mount status..."
if systemctl is-active storage-data-nas-media.mount &>/dev/null; then
    print_ok "NFS mount is currently active"
else
    print_error "NFS mount is NOT currently active"
    echo "   Fix: sudo systemctl start storage-data-nas-media.mount"
fi
echo ""

# Check 4: Docker wait-for-NFS override
echo "Checking Docker/NFS dependency..."
if [ -f /etc/systemd/system/docker.service.d/wait-for-nfs.conf ]; then
    print_ok "Docker wait-for-NFS override is configured"
    
    # Verify content
    if grep -q "After=storage-data-nas-media.mount" /etc/systemd/system/docker.service.d/wait-for-nfs.conf && \
       grep -q "Requires=storage-data-nas-media.mount" /etc/systemd/system/docker.service.d/wait-for-nfs.conf; then
        print_ok "Override file has correct content"
    else
        print_warning "Override file exists but content may be incorrect"
    fi
else
    print_error "Docker wait-for-NFS override is NOT configured"
    echo "   Fix: sudo mkdir -p /etc/systemd/system/docker.service.d"
    echo "        sudo cp systemd/docker-wait-for-nfs.conf /etc/systemd/system/docker.service.d/wait-for-nfs.conf"
    echo "        sudo systemctl daemon-reload"
fi
echo ""

# Check 5: Docker Compose file exists
echo "Checking Docker Compose configuration..."
if [ -f docker-compose.yml ]; then
    print_ok "docker-compose.yml found"
else
    print_error "docker-compose.yml NOT found"
    echo "   Are you in the correct directory? (should be /opt/media-stack)"
fi
echo ""

# Check 6: Container restart policies
echo "Checking container restart policies..."
if command -v docker &>/dev/null && docker ps -q &>/dev/null; then
    CONTAINERS=("sabnzbd" "sonarr" "radarr" "jellyfin")
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            RESTART_POLICY=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$container" 2>/dev/null)
            if [ "$RESTART_POLICY" = "unless-stopped" ] || [ "$RESTART_POLICY" = "always" ]; then
                print_ok "$container: restart policy is '$RESTART_POLICY'"
            else
                print_warning "$container: restart policy is '$RESTART_POLICY' (should be 'unless-stopped')"
            fi
        else
            print_warning "$container: container not found (may not be created yet)"
        fi
    done
else
    print_warning "Cannot check containers (Docker not running or no permission)"
fi
echo ""

# Check 7: Mount point exists
echo "Checking mount point..."
if [ -d /storage/data/nas/media ]; then
    print_ok "NFS mount point directory exists"
else
    print_error "NFS mount point directory does NOT exist"
    echo "   Fix: sudo mkdir -p /storage/data/nas/media"
fi
echo ""

# Check 8: Local download directories
echo "Checking local download directories..."
if [ -d /storage/data/local/downloads/incomplete ] && [ -d /storage/data/local/downloads/complete ]; then
    print_ok "Local download directories exist"
else
    print_error "Local download directories are missing"
    echo "   Fix: sudo ./scripts/setup-directories.sh"
fi
echo ""

# Summary
echo "=============================================="
echo "Summary:"
echo "=============================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your system is properly configured to:"
    echo "  1. Mount NFS on boot"
    echo "  2. Start Docker after NFS is ready"
    echo "  3. Auto-start all containers"
    echo ""
    echo "Test with: sudo reboot"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "System should work, but review warnings above."
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Please fix the errors above before rebooting."
    exit 1
fi

# Suggest reboot test
echo ""
echo "To test boot configuration:"
echo "  1. sudo reboot"
echo "  2. Wait 1-2 minutes after reboot"
echo "  3. Check: mount | grep media"
echo "  4. Check: docker-compose ps"
echo ""
