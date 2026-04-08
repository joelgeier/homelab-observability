#!/usr/bin/env bash
# ==============================================================================
# 00-root-bootstrap.sh — run as ROOT before any other homelab-observability script
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/00-root-bootstrap.sh
# VERSION:  v0.1  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Installs sudo, creates labadmin user with correct group membership,
# copies SSH authorized_keys, and clones the homelab-observability repo. Must run
# as root before any other script since sudo does not exist on a fresh
# Debian 13 install when a root password was set during installation.
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#     v0.1  2026-04-08  Initial release - adapted from homelab-base
#
# ==============================================================================
#
# IDEMPOTENT — safe to run multiple times.
# Each step checks current state before acting. Running on a host where
# sudo and labadmin already exist will report their state and exit cleanly.
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Debian 13 does not install sudo when a root password is set during
# installation. All other homelab-observability scripts use sudo and will fail
# immediately without it.
#
# This script must be run as root BEFORE any other script. It:
#   1. Installs sudo (if missing)
#   2. Creates the labadmin user (if missing)
#   3. Adds labadmin to the sudo group (if not already)
#   4. Copies SSH authorized_keys from calling user (if available)
#   5. Optionally clones the homelab-observability repo into labadmin home
#
# USAGE
# ──────────────────────────────────────────────────────────────────────────────
#   su -
#   bash /path/to/scripts/00-root-bootstrap.sh
#
#   Or from your install user:
#   su -c "bash scripts/00-root-bootstrap.sh" root
#
# WHY labadmin
# ──────────────────────────────────────────────────────────────────────────────
# A consistent admin username across all labhosts means Ansible inventory,
# Terraform provisioners, and rebuild scripts never need per-host user config.
# All scripts, all hosts: labadmin with sudo.
#
# AFTER RUNNING
# ──────────────────────────────────────────────────────────────────────────────
#   1. exit   (leave root session)
#   2. Log in as labadmin
#   3. passwd  (change from temporary password immediately)
#   4. cd ~/homelab-observability && bash scripts/01-preflight.sh
#
# ==============================================================================
set -euo pipefail

LABADMIN_USER="labadmin"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}    $*"; }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; exit 1; }

echo ""
echo "========================================"
echo "  homelab-observability bootstrap"
echo "  run as root — establishes sudo + $LABADMIN_USER"
echo "  host: $(hostname)"
echo "========================================"

# ── Must run as root ───────────────────────────────────────────────────────────
section "Privilege check"
if [[ "$(id -u)" -ne 0 ]]; then
  fail "Must run as root. Use: su -c 'bash scripts/00-root-bootstrap.sh' root"
fi
ok "Running as root"

# ── Install sudo ───────────────────────────────────────────────────────────────
section "sudo"
if command -v sudo &>/dev/null; then
  skip "sudo already installed — $(sudo --version | head -1)"
else
  info "sudo not found — installing..."
  apt-get update -q
  apt-get install -y sudo > /dev/null 2>&1
  ok "sudo installed — $(sudo --version | head -1)"
fi

# ── Create labadmin user ───────────────────────────────────────────────────────
section "labadmin user"
if id "$LABADMIN_USER" &>/dev/null; then
  skip "User '$LABADMIN_USER' already exists"
  info "Home:  $(getent passwd "$LABADMIN_USER" | cut -d: -f6)"
  info "Shell: $(getent passwd "$LABADMIN_USER" | cut -d: -f7)"
else
  info "Creating user $LABADMIN_USER..."
  useradd \
    --create-home \
    --shell /bin/bash \
    --comment "Homelab admin — consistent across all labhosts" \
    "$LABADMIN_USER"
  ok "User '$LABADMIN_USER' created"
  echo ""
  echo "  Set a password for $LABADMIN_USER (change on first login):"
  passwd "$LABADMIN_USER"
  echo ""
fi

# ── Add to sudo group ──────────────────────────────────────────────────────────
section "sudo group membership"
if groups "$LABADMIN_USER" | grep -q '\bsudo\b'; then
  skip "$LABADMIN_USER already in sudo group"
else
  info "Adding $LABADMIN_USER to sudo group..."
  usermod -aG sudo "$LABADMIN_USER"
  ok "$LABADMIN_USER added to sudo group"
fi

# ── Verify sudoers config ──────────────────────────────────────────────────────
section "sudoers configuration"
if grep -q "^%sudo" /etc/sudoers; then
  skip "%sudo group already has sudoers access"
else
  info "Adding %sudo entry to /etc/sudoers..."
  echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
  ok "%sudo entry added"
fi

# ── Copy SSH authorized_keys if available ──────────────────────────────────────
section "SSH authorized_keys"
LABADMIN_HOME=$(getent passwd "$LABADMIN_USER" | cut -d: -f6)
LABADMIN_SSH="$LABADMIN_HOME/.ssh"
LABADMIN_KEYS="$LABADMIN_SSH/authorized_keys"

if [[ -f "$LABADMIN_KEYS" ]]; then
  KEY_COUNT=$(wc -l < "$LABADMIN_KEYS")
  skip "authorized_keys already exists ($KEY_COUNT key(s))"
else
  # Try to find keys from the SUDO_USER env var (set when using su -c)
  CALLER_HOME=""
  if [[ -n "${SUDO_USER:-}" ]]; then
    CALLER_HOME=$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6 || echo "")
  fi

  if [[ -n "$CALLER_HOME" && -f "$CALLER_HOME/.ssh/authorized_keys" ]]; then
    info "Copying SSH keys from ${SUDO_USER} to $LABADMIN_USER..."
    mkdir -p "$LABADMIN_SSH"
    cp "$CALLER_HOME/.ssh/authorized_keys" "$LABADMIN_KEYS"
    chown -R "$LABADMIN_USER:$LABADMIN_USER" "$LABADMIN_SSH"
    chmod 700 "$LABADMIN_SSH"
    chmod 600 "$LABADMIN_KEYS"
    ok "SSH authorized_keys copied ($(wc -l < "$LABADMIN_KEYS") key(s))"
  else
    info "No SSH authorized_keys found to copy"
    info "To add your SSH key manually after logging in as $LABADMIN_USER:"
    info "  ssh-copy-id labadmin@$(hostname -I | awk '{print $1}')"
    info "  or: mkdir -p ~/.ssh && nano ~/.ssh/authorized_keys"
  fi
fi

# ── Clone homelab-observability repo ───────────────────────────────────────────
section "homelab-observability repository"
REPO_DIR="$LABADMIN_HOME/homelab-observability"

if [[ -d "$REPO_DIR/.git" ]]; then
  skip "homelab-observability repo already at $REPO_DIR"
  info "Pulling latest changes..."
  sudo -u "$LABADMIN_USER" git -C "$REPO_DIR" pull --ff-only 2>/dev/null && \
    ok "Repo updated" || \
    info "Could not pull — check network or run manually: git -C ~/homelab-observability pull"
elif command -v git &>/dev/null; then
  info "Cloning homelab-observability into $REPO_DIR..."
  if sudo -u "$LABADMIN_USER" git clone \
    https://github.com/joelgeier/homelab-observability.git \
    "$REPO_DIR" 2>/dev/null; then
    ok "homelab-observability cloned to $REPO_DIR"
  else
    info "Could not clone repo (network or git issue) — clone manually:"
    info "  git clone https://github.com/joelgeier/homelab-observability.git ~/homelab-observability"
  fi
else
  info "git not yet installed — repo will be cloned after 02-packages.sh runs"
  info "  Once git is installed: git clone https://github.com/joelgeier/homelab-observability.git ~/homelab-observability"
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Bootstrap complete — $(hostname)"
echo "========================================"
echo ""
echo "  User:        $LABADMIN_USER"
echo "  Home:        $LABADMIN_HOME"
echo "  sudo access: yes"
echo "  SSH keys:    $(if [[ -f "$LABADMIN_KEYS" ]]; then echo "$(wc -l < "$LABADMIN_KEYS") key(s) present"; else echo "none — add manually"; fi)"
echo "  Repo:        $(if [[ -d "$REPO_DIR/.git" ]]; then echo "$REPO_DIR"; else echo "not cloned yet"; fi)"
echo ""
echo "  NEXT STEPS:"
echo "  ─────────────────────────────────────"
echo "  1. Exit root:          exit"
echo "  2. Login as labadmin:  ssh $LABADMIN_USER@$(hostname -I | awk '{print $1}')"
echo "  3. Change password:    passwd"
echo "  4. Go to repo:         cd ~/homelab-observability"
echo "  5. Run preflight:      bash scripts/01-preflight.sh"
echo ""
