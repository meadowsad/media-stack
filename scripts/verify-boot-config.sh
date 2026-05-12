#!/usr/bin/env bash
# verify-boot-config.sh — verify all auto-start components are correctly configured
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "========================================"
echo "  Media Stack Boot Configuration Check"
echo "========================================"
echo ""

# --- Docker ---
echo "--- Docker ---"
if command -v docker &>/dev/null; then
  ok "docker is installed"
else
  fail "docker not installed"
fi

if systemctl is-active --quiet docker; then
  ok "Docker service is active"
else
  fail "Docker service not active — fix: sudo systemctl start docker"
fi

if systemctl is-enabled --quiet docker; then
  ok "Docker service enabled on boot"
else
  fail "Docker not enabled on boot — fix: sudo systemctl enable docker"
fi

# --- Docker Compose V2 ---
echo ""
echo "--- Docker Compose V2 ---"
if docker compose version &>/dev/null; then
  VER=$(docker compose version --short 2>/dev/null || docker compose version | awk '{print $NF}')
  ok "Docker Compose V2 available ($VER)"
else
  fail "Docker Compose V2 not available — fix: sudo apt install docker-compose-plugin"
fi

# --- NFS Mount ---
echo ""
echo "--- NFS Mount ---"
MOUNT_UNIT="storage-data-nas-media.mount"

if systemctl list-unit-files "$MOUNT_UNIT" 2>/dev/null | grep -q "$MOUNT_UNIT"; then
  ok "Systemd unit $MOUNT_UNIT exists"
else
  fail "$MOUNT_UNIT not found — copy systemd/storage-data-nas-media.mount to /etc/systemd/system/ and run: sudo systemctl daemon-reload"
fi

if systemctl is-enabled --quiet "$MOUNT_UNIT" 2>/dev/null; then
  ok "$MOUNT_UNIT enabled on boot"
else
  fail "$MOUNT_UNIT not enabled — fix: sudo systemctl enable $MOUNT_UNIT"
fi

if systemctl is-active --quiet "$MOUNT_UNIT" 2>/dev/null; then
  ok "$MOUNT_UNIT is active (NFS mounted)"
else
  fail "$MOUNT_UNIT not active — fix: sudo systemctl start $MOUNT_UNIT"
fi

# --- Docker NFS Dependency ---
echo ""
echo "--- Docker NFS Dependency ---"
OVERRIDE="/etc/systemd/system/docker.service.d/wait-for-nfs.conf"
if [[ -f "$OVERRIDE" ]]; then
  ok "Docker NFS wait override in place ($OVERRIDE)"
else
  fail "Docker NFS override missing — copy systemd/docker-wait-for-nfs.conf to $OVERRIDE then: sudo systemctl daemon-reload"
fi

# --- Container Restart Policies ---
echo ""
echo "--- Container Restart Policies ---"
COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for svc in sabnzbd sonarr radarr jellyfin; do
  POLICY=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$svc" 2>/dev/null || echo "not_found")
  if [[ "$POLICY" == "unless-stopped" ]]; then
    ok "$svc: restart policy is $POLICY"
  elif [[ "$POLICY" == "not_found" ]]; then
    warn "$svc: container not running — start with: docker compose -f $COMPOSE_DIR/docker-compose.yml up -d"
  else
    fail "$svc: restart policy is '$POLICY' (expected 'unless-stopped')"
  fi
done

echo ""
echo "========================================"
echo "  Check complete."
echo "========================================"
