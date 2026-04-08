#!/usr/bin/env bash
# ==============================================================================
# 05-init-directories.sh — create base observability directory structure
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/05-init-directories.sh
# VERSION:  v0.1  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Creates the base /mnt/data/homelab-observability directory structure.
# Tool-specific subdirectories are created incrementally as each docker-compose
# stack is deployed. This script only creates the root and ensures proper
# permissions.
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#     v0.1  2026-04-08  Initial release
#
# ==============================================================================
#
# IDEMPOTENT — safe to run multiple times.
# Checks if directories exist before creating them.
#
# Run as labadmin (with sudo) after 04-tailscale.sh completes.
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}    $*"; }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; exit 1; }

echo ""
echo "========================================"
echo "  homelab-observability: init directories"
echo "  host: $(hostname)  |  user: $(whoami)"
echo "========================================"

# ── Load .env if available ────────────────────────────────────────────────────
section "Configuration"
if [[ -f ~/homelab-observability/.env ]]; then
  source ~/homelab-observability/.env
  ok ".env loaded"
else
  info ".env not found — using defaults"
fi

# ── Set DATA_ROOT ─────────────────────────────────────────────────────────────
DATA_ROOT="${DATA_ROOT:-/mnt/data/homelab-observability}"
info "DATA_ROOT: $DATA_ROOT"

# ── Create base directory ─────────────────────────────────────────────────────
section "Base directory structure"

if [[ -d "$DATA_ROOT" ]]; then
  skip "$DATA_ROOT already exists"
else
  info "Creating $DATA_ROOT..."
  sudo mkdir -p "$DATA_ROOT"
  ok "Directory created"
fi

# ── Set ownership ─────────────────────────────────────────────────────────────
section "Permissions"
CURRENT_USER=$(whoami)
CURRENT_OWNER=$(stat -c '%U' "$DATA_ROOT" 2>/dev/null || echo "unknown")

if [[ "$CURRENT_OWNER" == "$CURRENT_USER" ]]; then
  skip "$DATA_ROOT already owned by $CURRENT_USER"
else
  info "Setting ownership to $CURRENT_USER:$CURRENT_USER..."
  sudo chown "$CURRENT_USER:$CURRENT_USER" "$DATA_ROOT"
  ok "Ownership set"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Directory initialization complete"
echo "========================================"
echo ""
echo "  Location:    $DATA_ROOT"
echo "  Owner:       $(stat -c '%U:%G' "$DATA_ROOT")"
echo "  Permissions: $(stat -c '%a' "$DATA_ROOT")"
echo ""
echo "  Tool-specific subdirectories will be created"
echo "  automatically by each docker-compose stack."
echo ""
echo "  Next steps:"
echo "  1. Create .env from .env.example"
echo "  2. Begin Phase I deployment (Portainer, Uptime Kuma)"
echo ""
