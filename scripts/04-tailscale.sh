#!/usr/bin/env bash
# ==============================================================================
# 04-tailscale.sh — install Tailscale on Debian 13
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/04-tailscale.sh
# VERSION:  v0.1  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Installs Tailscale from the official install script. Checks if already
# installed and running before acting. Run separately on both the Proxmox
# host and the Debian VM — each registers as a separate tailnet device.
# Authentication (tailscale up) must be run manually after install.
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#     v0.1  2026-04-08  Initial release
#
# ==============================================================================
#
# IDEMPOTENT — safe to run multiple times, on any host, at any time.
# Checks whether Tailscale is installed and running before acting.
# Running on a host with Tailscale already installed reports current
# status and exits cleanly — nothing is reinstalled.
#
# Run on BOTH the Proxmox host and the Debian VM separately.
# Each installation registers as a separate device on the tailnet.
# This is deliberate — see docs/tailscale-config.md for why.
#
# After running this script, authenticate manually:
#   sudo tailscale up --hostname=labhost01
#
# https://tailscale.com/download/linux
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}    $*"; }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }

print_next_steps() {
  echo ""
  echo "  NEXT — authenticate this device to your tailnet:"
  echo ""
  echo "    sudo tailscale up --hostname=$(hostname)"
  echo ""
  echo "  Optional flags:"
  echo "    --accept-routes          accept subnet routes from other nodes"
  echo "    --advertise-exit-node    make this node an exit node"
  echo ""
  echo "  Expose Traefik via Tailscale funnel (port 8443):"
  echo "    sudo tailscale funnel --bg 8443"
  echo ""
  echo "  Check tailnet status:"
  echo "    tailscale status"
  echo ""
  echo "  See docs/tailscale-config.md for full configuration notes."
  echo ""
}

echo ""
echo "========================================"
echo "  homelab-observability: Tailscale install"
echo "  host: $(hostname)  |  user: $(whoami)"
echo "========================================"

# ── Check if Tailscale is already installed ───────────────────────────────────
section "Checking Tailscale state"

if command -v tailscale &>/dev/null; then
  TS_VER=$(tailscale version 2>/dev/null | head -1)
  skip "Tailscale already installed — $TS_VER"

  info "Checking service status..."
  if sudo systemctl is-active --quiet tailscaled 2>/dev/null; then
    ok "tailscaled service is running"
  else
    info "tailscaled not running — starting..."
    sudo systemctl start tailscaled && ok "tailscaled started"
  fi

  if sudo systemctl is-enabled --quiet tailscaled 2>/dev/null; then
    skip "tailscaled already enabled at boot"
  else
    sudo systemctl enable tailscaled && ok "tailscaled enabled at boot"
  fi

  info "Current tailnet status:"
  tailscale status 2>/dev/null | sed 's/^/          /' || \
    echo "          Not authenticated yet — run: sudo tailscale up --hostname=$(hostname)"

  echo ""
  echo "========================================"
  echo "  Tailscale already installed"
  echo "  host: $(hostname) — nothing to do"
  echo "========================================"

  print_next_steps
  exit 0
fi

# ── Install Tailscale ─────────────────────────────────────────────────────────
section "Installing Tailscale"
info "Running official Tailscale install script..."
curl -fsSL https://tailscale.com/install.sh | sh
ok "Tailscale installed"

# ── Enable and start service ──────────────────────────────────────────────────
section "Tailscale service"

if sudo systemctl is-enabled --quiet tailscaled 2>/dev/null; then
  skip "tailscaled already enabled at boot"
else
  sudo systemctl enable tailscaled
  ok "tailscaled enabled at boot"
fi

if sudo systemctl is-active --quiet tailscaled 2>/dev/null; then
  skip "tailscaled already running"
else
  sudo systemctl start tailscaled
  ok "tailscaled started"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
section "Verification"
ok "Tailscale version: $(tailscale version | head -1)"
ok "Service status:    $(sudo systemctl is-active tailscaled)"

echo ""
echo "========================================"
echo "  Tailscale install complete"
echo "  host: $(hostname)"
echo "========================================"

print_next_steps
