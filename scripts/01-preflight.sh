#!/usr/bin/env bash
# ==============================================================================
# 01-preflight.sh — validate environment before running install scripts
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/01-preflight.sh
# VERSION:  v0.1  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Read-only system check. Verifies OS, architecture, user privileges,
# sudo, hostname, memory, disk, internet, Docker, Tailscale, Docker
# networks, and observability directory structure. Run at any time to check
# deployment readiness. Makes no changes to the system.
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#     v0.1  2026-04-08  Initial release - adapted from homelab-base
#
# ==============================================================================
#
# IDEMPOTENT — read-only check, makes no changes to the system.
# Safe to run at any time on any host. Run this whenever you want to
# verify the state of labhost00 before proceeding with any install step.
#
# Run as labadmin AFTER 00-root-bootstrap.sh has been run as root.
# 00-root-bootstrap.sh installs sudo and creates the labadmin user.
#
# EXIT CODES
#   0 — all checks passed (or only warnings)
#   1 — one or more checks failed — resolve before continuing
# ==============================================================================
set -euo pipefail

PASS=0; WARN=0; FAIL=0

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[PASS]${NC}    $*"; PASS=$((PASS+1)); }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; WARN=$((WARN+1)); }
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; FAIL=$((FAIL+1)); }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }

echo ""
echo "========================================"
echo "  homelab-observability preflight check"
echo "  host: $(hostname)  |  user: $(whoami)"
echo "  date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# ── OS ────────────────────────────────────────────────────────────────────────
section "Operating system"
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "debian" && "$VERSION_ID" == "13" ]]; then
    ok "Debian 13 (trixie) — $PRETTY_NAME"
  elif [[ "$ID" == "debian" ]]; then
    warn "Debian $VERSION_ID detected — scripts target Debian 13 (trixie). Proceed with caution."
  else
    fail "Expected Debian — got: $PRETTY_NAME"
  fi
else
  fail "/etc/os-release not found — cannot determine OS"
fi

# ── Architecture ─────────────────────────────────────────────────────────────
section "Architecture"
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  ok "Architecture: x86_64"
else
  warn "Architecture is $ARCH — scripts and Docker install assume x86_64. Some packages may differ."
fi

# ── User ──────────────────────────────────────────────────────────────────────
section "User and privileges"

CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" == "labadmin" ]]; then
  ok "Running as labadmin — expected admin user"
elif [[ "$CURRENT_USER" == "root" ]]; then
  warn "Running as root — should run as labadmin for install scripts. Run 00-root-bootstrap.sh first."
else
  warn "Running as $CURRENT_USER — expected labadmin. Scripts will still work if this user has sudo."
fi

# ── sudo ──────────────────────────────────────────────────────────────────────
section "sudo"
if ! command -v sudo &>/dev/null; then
  fail "sudo is not installed — run 00-root-bootstrap.sh as root first"
  info "Command: su -c 'bash scripts/00-root-bootstrap.sh' root"
else
  ok "sudo is installed — $(sudo --version | head -1)"

  if sudo -n true 2>/dev/null; then
    ok "sudo access: confirmed (passwordless)"
  elif sudo true 2>/dev/null; then
    ok "sudo access: confirmed (password required)"
  else
    fail "sudo is installed but current user ($CURRENT_USER) has no sudo access"
    info "Ensure $CURRENT_USER is in the sudo group: usermod -aG sudo $CURRENT_USER"
  fi
fi

# ── labadmin user ─────────────────────────────────────────────────────────────
section "labadmin user"
if id labadmin &>/dev/null; then
  ok "labadmin user exists"
  if groups labadmin | grep -q '\bsudo\b'; then
    ok "labadmin is in the sudo group"
  else
    warn "labadmin exists but is not in the sudo group — run 00-root-bootstrap.sh"
  fi
else
  warn "labadmin user not found — run 00-root-bootstrap.sh as root to create it"
fi

# ── Hostname ──────────────────────────────────────────────────────────────────
section "Hostname"
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == "localhost" || "$HOSTNAME" == "debian" || -z "$HOSTNAME" ]]; then
  warn "Hostname is '$HOSTNAME' — set a proper hostname before deploying:"
  info "  sudo hostnamectl set-hostname labhost00"
else
  ok "Hostname: $HOSTNAME"
fi

# ── RAM ───────────────────────────────────────────────────────────────────────
section "Memory"
TOTAL_RAM_GB=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
TOTAL_RAM_INT=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
if [[ "$TOTAL_RAM_INT" -ge 16 ]]; then
  ok "RAM: ${TOTAL_RAM_GB}GB (sufficient for full observability stack)"
elif [[ "$TOTAL_RAM_INT" -ge 8 ]]; then
  warn "RAM: ${TOTAL_RAM_GB}GB — sufficient for Phase I-III, but tight for ELK/Graylog/Wazuh (Phase IV)"
else
  fail "RAM: ${TOTAL_RAM_GB}GB — insufficient for observability stack (minimum 8GB, recommend 16GB+)"
fi

# ── Disk ──────────────────────────────────────────────────────────────────────
section "Disk space"
ROOT_FREE_GB=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
if [[ "$ROOT_FREE_GB" -ge 50 ]]; then
  ok "Root partition: ${ROOT_FREE_GB}GB free"
elif [[ "$ROOT_FREE_GB" -ge 30 ]]; then
  warn "Root partition: ${ROOT_FREE_GB}GB free — recommend at least 50GB for log storage and metrics"
else
  fail "Root partition: ${ROOT_FREE_GB}GB free — insufficient (minimum 30GB, recommend 50GB+)"
fi

# ── Internet ──────────────────────────────────────────────────────────────────
section "Internet connectivity"
# Try curl first (preferred), fallback to wget, then ping (for minimal installs)
if command -v curl &>/dev/null; then
  if curl -s --max-time 5 https://debian.org > /dev/null 2>&1; then
    ok "Internet reachable (HTTPS to debian.org via curl)"
  elif curl -s --max-time 5 https://1.1.1.1 > /dev/null 2>&1; then
    ok "Internet reachable (HTTPS to 1.1.1.1 via curl)"
  else
    fail "No internet connectivity — required for package installation and Docker image pulls"
  fi
elif command -v wget &>/dev/null; then
  if wget -q --timeout=5 --spider https://debian.org 2>&1; then
    ok "Internet reachable (HTTPS to debian.org via wget)"
  elif wget -q --timeout=5 --spider https://1.1.1.1 2>&1; then
    ok "Internet reachable (HTTPS to 1.1.1.1 via wget)"
  else
    fail "No internet connectivity — required for package installation and Docker image pulls"
  fi
else
  # Fallback to ping for minimal Debian installs (curl/wget not yet installed)
  info "curl/wget not installed yet — using ping for connectivity check"
  if ping -c 2 -W 3 debian.org > /dev/null 2>&1; then
    ok "Internet reachable (ping to debian.org) — DNS resolution working"
  elif ping -c 2 -W 3 1.1.1.1 > /dev/null 2>&1; then
    ok "Internet reachable (ping to 1.1.1.1) — network connectivity confirmed"
  else
    fail "No internet connectivity — required for package installation and Docker image pulls"
  fi
fi

# ── Docker ────────────────────────────────────────────────────────────────────
section "Docker (informational — run 03-docker.sh if missing)"
if command -v docker &>/dev/null; then
  ok "Docker installed — $(docker --version)"
  if docker compose version &>/dev/null 2>&1; then
    ok "Docker Compose — $(docker compose version)"
  else
    warn "Docker installed but Compose plugin missing — run 03-docker.sh"
  fi
  if sudo systemctl is-active --quiet docker 2>/dev/null; then
    ok "Docker service is running"
  else
    warn "Docker installed but service not running — sudo systemctl start docker"
  fi
  if groups "$CURRENT_USER" | grep -q '\bdocker\b'; then
    ok "User $CURRENT_USER is in docker group"
  else
    warn "User $CURRENT_USER not in docker group — run 03-docker.sh or: sudo usermod -aG docker $CURRENT_USER"
  fi
else
  info "Docker not installed — run 03-docker.sh"
fi

# ── Tailscale ─────────────────────────────────────────────────────────────────
section "Tailscale (informational — run 04-tailscale.sh if missing)"
if command -v tailscale &>/dev/null; then
  ok "Tailscale installed — $(tailscale version | head -1)"
  if sudo systemctl is-active --quiet tailscaled 2>/dev/null; then
    ok "tailscaled service is running"
    TS_STATUS=$(tailscale status 2>/dev/null | head -1 || echo "unknown")
    info "Status: $TS_STATUS"
  else
    warn "Tailscale installed but tailscaled not running"
  fi
else
  info "Tailscale not installed — run 04-tailscale.sh"
fi

# ── Docker networks ───────────────────────────────────────────────────────────
section "Docker networks (informational)"
if command -v docker &>/dev/null && sudo systemctl is-active --quiet docker 2>/dev/null; then
  info "Docker networks will be created per-stack during deployment"
  info "  Each observability tool will define its own network in docker-compose.yml"
else
  info "Docker not running — networks will be checked after 03-docker.sh"
fi

# ── Observability host directories ────────────────────────────────────────────
section "Observability host directories"
# DATA_PATH matches project standard — /mnt/data/homelab-observability
DATA_PATH="${DATA_PATH:-/mnt/data/homelab-observability}"

if [[ -d "$DATA_PATH" ]]; then
  ok "$DATA_PATH exists (data root)"
else
  warn "$DATA_PATH missing — create before deployment:"
  info "  sudo mkdir -p $DATA_PATH"
  info "  sudo chown labadmin:labadmin $DATA_PATH"
fi

# Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Preflight results — $(hostname)"
echo "========================================"
echo -e "  ${GREEN}Passed${NC}:   $PASS"
echo -e "  ${YELLOW}Warnings${NC}: $WARN"
echo -e "  ${RED}Failed${NC}:   $FAIL"
echo "========================================"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "  ✗ Preflight FAILED — resolve the failures above before continuing."
  echo ""
  exit 1
elif [[ "$WARN" -gt 0 ]]; then
  echo "  ⚠ Preflight passed with warnings — review them above."
  echo "    Warnings are non-blocking but should be addressed."
  echo ""
  exit 0
else
  echo "  ✓ Preflight passed — proceed with 02-packages.sh"
  echo ""
  exit 0
fi
