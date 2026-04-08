#!/usr/bin/env bash
# ==============================================================================
# 03-docker.sh — install Docker CE from the official Docker repository
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/03-docker.sh
# VERSION:  v0.3  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Installs Docker CE from the official Docker repository (not the outdated
# Debian apt version). Idempotent — safe to run multiple times on any host.
# Also deploys the Portainer Agent as a standalone container (not in the
# compose stack) so it survives stack teardowns.
#
# Run as labadmin (with sudo) after 02-packages.sh.
# https://docs.docker.com/engine/install/debian/
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#   v0.1  2026-04-08  Initial — Docker CE install, daemon.json config
#   v0.2  2026-04-08  Added Portainer Agent deployment (standalone, not compose)
#                     Fix: warn function missing from helper definitions
#                     Fix: early exit block was skipping Portainer Agent section
#   v0.3  2026-04-08  Fix: container status detection blank-line capture bug
#                     Separate docker inspect existence check from status check
#
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }
err()     { echo -e "${RED}[FAIL]${NC}    $*"; }

echo ""
echo "========================================"
echo "  homelab-observability: Docker CE install"
echo "  host: $(hostname)  |  user: $(whoami)"
echo "========================================"

# ── Check if Docker is already fully installed ───────────────────────────────
section "Checking Docker state"

DOCKER_INSTALLED=false
COMPOSE_INSTALLED=false
USER_IN_GROUP=false

if command -v docker &>/dev/null; then
  DOCKER_VER=$(docker --version 2>/dev/null)
  skip "Docker already installed — $DOCKER_VER"
  DOCKER_INSTALLED=true
else
  info "Docker not found — will install"
fi

if docker compose version &>/dev/null 2>&1; then
  COMPOSE_VER=$(docker compose version 2>/dev/null)
  skip "Docker Compose already available — $COMPOSE_VER"
  COMPOSE_INSTALLED=true
else
  info "Docker Compose plugin not found — will install"
fi

if groups "$USER" | grep -q '\bdocker\b'; then
  skip "User $USER already in docker group"
  USER_IN_GROUP=true
else
  info "User $USER not in docker group — will add"
fi

# If everything is already in place, verify service then fall through to
# Portainer Agent check — do NOT exit early, agent must always be checked
if $DOCKER_INSTALLED && $COMPOSE_INSTALLED && $USER_IN_GROUP; then
  section "Verifying existing installation"
  info "Checking Docker service status..."
  if sudo systemctl is-active --quiet docker; then
    ok "Docker service is running"
  else
    info "Docker service not running — starting..."
    sudo systemctl start docker && ok "Docker service started"
  fi
  echo ""
  echo "========================================"
  echo "  Docker CE already fully installed"
  echo "  $(hostname) — skipping install, checking agent..."
  echo "========================================"
  echo ""
  docker --version
  docker compose version
  echo ""
  # Fall through to Portainer Agent section below
  SKIP_INSTALL=true
else
  SKIP_INSTALL=false
fi

if [[ "$SKIP_INSTALL" == "true" ]]; then
  # Jump directly to Portainer Agent — skip all install sections
  true
else
  : # continue with install sections below
fi

# ── Install sections (skipped if Docker already present) ─────────────────────
if [[ "${SKIP_INSTALL:-false}" == "false" ]]; then

# ── Remove conflicting packages ───────────────────────────────────────────────
section "Removing conflicting packages"
CONFLICTS=(docker.io docker-doc docker-compose podman-docker containerd runc)
for pkg in "${CONFLICTS[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    info "Removing conflicting package: $pkg"
    sudo apt-get remove -y "$pkg" > /dev/null 2>&1
    ok "Removed $pkg"
  else
    skip "$pkg — not installed (no conflict)"
  fi
done

# ── Add Docker GPG key ────────────────────────────────────────────────────────
section "Docker repository setup"

KEYRING_PATH="/etc/apt/keyrings/docker.asc"
if [[ -f "$KEYRING_PATH" ]]; then
  skip "Docker GPG key already present at $KEYRING_PATH"
else
  info "Adding Docker GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o "$KEYRING_PATH"
  sudo chmod a+r "$KEYRING_PATH"
  ok "Docker GPG key added"
fi

# ── Add Docker apt repository ─────────────────────────────────────────────────
REPO_FILE="/etc/apt/sources.list.d/docker.list"
if [[ -f "$REPO_FILE" ]]; then
  skip "Docker apt repository already configured at $REPO_FILE"
else
  info "Adding Docker apt repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING_PATH}] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee "$REPO_FILE" > /dev/null
  ok "Docker apt repository added"
fi

# ── Update package index ──────────────────────────────────────────────────────
info "Updating package index..."
sudo apt-get update -q && ok "Package index updated"

# ── Install Docker packages ───────────────────────────────────────────────────
section "Installing Docker CE packages"

DOCKER_PKGS=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
for pkg in "${DOCKER_PKGS[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    skip "$pkg — already installed"
  else
    info "Installing $pkg..."
    sudo apt-get install -y "$pkg" > /dev/null 2>&1
    ok "$pkg installed"
  fi
done

# ── Add user to docker group ──────────────────────────────────────────────────
section "Docker group membership"
if groups "$USER" | grep -q '\bdocker\b'; then
  skip "User $USER already in docker group"
else
  info "Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  ok "$USER added to docker group"
  echo ""
  echo "  ⚠  Group change requires logout/login to take effect."
  echo "     Run: newgrp docker   OR log out and back in."
fi

# ── Enable and start Docker service ──────────────────────────────────────────
section "Docker service"
if sudo systemctl is-enabled --quiet docker 2>/dev/null; then
  skip "Docker service already enabled at boot"
else
  info "Enabling Docker service at boot..."
  sudo systemctl enable docker
  ok "Docker service enabled"
fi

if sudo systemctl is-active --quiet docker 2>/dev/null; then
  skip "Docker service already running"
else
  info "Starting Docker service..."
  sudo systemctl start docker
  ok "Docker service started"
fi

# ── Configure Docker daemon ───────────────────────────────────────────────────
section "Docker daemon configuration (daemon.json)"
DAEMON_JSON="/etc/docker/daemon.json"
if [[ -f "$DAEMON_JSON" ]]; then
  skip "Docker daemon config already exists at $DAEMON_JSON"
  info "Current config:"
  cat "$DAEMON_JSON" | sed 's/^/          /'
else
  info "Writing $DAEMON_JSON with log rotation settings..."
  sudo tee "$DAEMON_JSON" > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "dns": ["1.1.1.1", "8.8.8.8"]
}
EOF
  sudo systemctl restart docker
  ok "Docker daemon configured (log rotation: 3 × 10MB per container)"
fi

fi # end SKIP_INSTALL

# ── Deploy Portainer Agent ────────────────────────────────────────────────────
# Portainer Agent is deployed here — NOT in the homelab-observability compose stack.
# Reason: the agent must survive stack teardowns and redeploys. If it lived
# in the compose stack, removing the stack would kill the agent and disconnect
# this labhost from the Portainer master on the QNAP.
#
# The agent is a permanent infrastructure component, deployed once after Docker
# is installed and never removed unless intentionally decommissioning the host.
#
# After running this script, register the labhost in Portainer master:
#   Environments → Add Environment → Agent → labhost tailnet IP:9001
section "Portainer Agent"

AGENT_NAME="portainer-agent"

# Check container existence first, then get status — avoids blank-line capture bug
if docker inspect "$AGENT_NAME" &>/dev/null; then
  AGENT_STATUS=$(docker inspect -f '{{.State.Status}}' "$AGENT_NAME" 2>/dev/null | tr -d '[:space:]')
else
  AGENT_STATUS="not found"
fi

if [[ "$AGENT_STATUS" == "running" ]]; then
  skip "Portainer Agent already running"
  info "Image: $(docker inspect --format '{{.Config.Image}}' $AGENT_NAME 2>/dev/null)"
elif [[ "$AGENT_STATUS" == "exited" || "$AGENT_STATUS" == "stopped" ]]; then
  info "Portainer Agent exists but is stopped — starting..."
  docker start "$AGENT_NAME" > /dev/null 2>&1
  ok "Portainer Agent started"
elif [[ "$AGENT_STATUS" == "not found" ]]; then
  info "Deploying Portainer Agent..."
  docker run -d \
    --name "$AGENT_NAME" \
    --restart unless-stopped \
    -p 9001:9001 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    portainer/agent:latest > /dev/null 2>&1
  ok "Portainer Agent deployed on port 9001"
  info "Register in Portainer master: Environments → Add → Agent → $(hostname -I | awk '{print $1}'):9001"
else
  warn "Portainer Agent in unexpected state: $AGENT_STATUS"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
section "Verification"
ok "Docker version:  $(docker --version)"
ok "Compose version: $(docker compose version)"
ok "Service status:  $(sudo systemctl is-active docker)"

echo ""
echo "========================================"
echo "  Docker CE install complete"
echo "  host: $(hostname)"
echo "========================================"
echo ""
echo "  Next: bash scripts/04-tailscale.sh"
echo ""
