#!/usr/bin/env bash
# ==============================================================================
# 02-packages.sh — install CLI tools on Debian 13
# ==============================================================================
#
# PROJECT:  homelab-observability
# FILE:     scripts/02-packages.sh
# VERSION:  v0.1  2026-04-08
#
# PURPOSE
# ──────────────────────────────────────────────────────────────────────────────
# Installs all essential CLI tools for managing labhost00. Each package
# is checked individually before installation — already-installed packages
# are skipped. Runs apt-get update first, reports a summary of installed
# vs skipped vs failed packages.
#
# CHANGELOG
# ──────────────────────────────────────────────────────────────────────────────
#     v0.1  2026-04-08  Initial release - adapted from homelab-base
#
# ==============================================================================
#
# IDEMPOTENT — safe to run multiple times, on any host, at any time.
# Each package is checked individually before installation.
# Already-installed packages are reported and skipped.
#
# Run as labadmin (with sudo) after 01-preflight.sh passes.
# ==============================================================================
set -euo pipefail

INSTALLED=0; SKIPPED=0; FAILED=0

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}    $*"; SKIPPED=$((SKIPPED+1)); }
info()    { echo    "          [INFO]  $*"; }
section() { echo ""; echo -e "${CYAN}── $* ──────────────────────────────────────────${NC}"; }
err()     { echo -e "${RED}[FAIL]${NC}    $*"; FAILED=$((FAILED+1)); }

# ── Check and install a single apt package ───────────────────────────────────
# Usage: pkg_install APT_PACKAGE_NAME [DISPLAY_NAME]
pkg_install() {
  local pkg="$1"
  local display="${2:-$1}"
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    skip "$display — already installed"
  else
    info "Installing $display..."
    if sudo apt-get install -y "$pkg" > /dev/null 2>&1; then
      ok "$display installed"
      INSTALLED=$((INSTALLED+1))
    else
      err "$display — install failed (run: sudo apt-get install -y $pkg)"
    fi
  fi
}

echo ""
echo "========================================"
echo "  homelab-observability: package install"
echo "  host: $(hostname)  |  user: $(whoami)"
echo "========================================"

section "Updating package index"
info "Running apt-get update..."
sudo apt-get update -q && ok "Package index updated"

section "Essentials missing from Debian 13 base"
pkg_install curl
pkg_install wget
pkg_install git
pkg_install zip
pkg_install unzip
pkg_install nano
pkg_install sudo
pkg_install ca-certificates
pkg_install gnupg
pkg_install apt-transport-https
pkg_install lsb-release
pkg_install openssh-client
pkg_install openssh-server

section "Shell"
pkg_install zsh
pkg_install tmux

section "Core command replacements"
pkg_install eza                  "eza (modern ls)"
pkg_install bat                  "bat/batcat (modern cat — alias: bat=batcat)"
pkg_install ripgrep              "ripgrep/rg (modern grep)"
pkg_install fd-find              "fd-find (modern find — alias: fd=fdfind)"
pkg_install zoxide               "zoxide (smart cd)"
pkg_install less

section "System monitoring"
pkg_install btop                 "btop (modern top)"
pkg_install htop
pkg_install glances
pkg_install procs
pkg_install ncdu
pkg_install duf                  "duf (modern df)"
pkg_install nala                 "nala (better apt frontend)"
pkg_install iotop
pkg_install lsof

section "File management"
pkg_install ranger
pkg_install nnn
pkg_install detox
pkg_install rsync
pkg_install sshfs
pkg_install plocate              "plocate (locate/updatedb — replaces mlocate in Debian 13)"
pkg_install tar

section "Productivity and workflow"
pkg_install fzf
pkg_install tealdeer             "tealdeer (tldr)"
pkg_install jq
pkg_install direnv
pkg_install parallel             "parallel (GNU parallel)"
pkg_install fastfetch            "fastfetch (replaces neofetch — removed from Debian 13)"
pkg_install etckeeper            "etckeeper (track /etc in git)"

section "Network tools"
pkg_install net-tools            "net-tools (netstat, ifconfig)"
pkg_install iproute2             "iproute2 (ip)"
pkg_install iputils-ping         "iputils-ping (ping)"
pkg_install dnsutils             "dnsutils (dig, nslookup)"
pkg_install nmap
pkg_install netcat-openbsd       "netcat-openbsd (nc)"
pkg_install traceroute
pkg_install iptables
pkg_install ufw

section "Editors"
pkg_install vim
pkg_install neovim

section "Security"
pkg_install fail2ban

section "Build tools and utilities"
pkg_install build-essential      "build-essential (make, gcc, g++)"
pkg_install make
pkg_install python3
pkg_install python3-pip

section "Post-install steps"

info "Refreshing locate database (updatedb)..."
if sudo updatedb 2>/dev/null; then
  ok "locate database updated"
else
  echo "          [WARN]  updatedb failed — run manually: sudo updatedb"
fi

info "Updating tldr pages..."
if command -v tldr &>/dev/null; then
  tldr --update 2>/dev/null && ok "tldr pages updated" || \
    echo "          [WARN]  tldr update failed — run manually: tldr --update"
else
  echo "          [WARN]  tldr not in PATH yet — may need shell restart"
fi

info "Initialising etckeeper (/etc tracked in git)..."
if sudo git -C /etc log --oneline -1 &>/dev/null 2>&1; then
  skip "etckeeper — /etc is already tracked in git"
else
  sudo etckeeper init 2>/dev/null && \
  sudo etckeeper commit "initial homelab-observability install" 2>/dev/null && \
  ok "etckeeper initialised" || \
  echo "          [WARN]  etckeeper init failed — run manually"
fi

section "Aliases to add to ~/.zshrc or ~/.bashrc"
echo ""
echo "  alias bat='batcat'"
echo "  alias fd='fdfind'"
echo "  eval \"\$(zoxide init zsh)\""
echo "  source /usr/share/doc/fzf/examples/key-bindings.zsh"
echo "  source /usr/share/doc/fzf/examples/completion.zsh"

echo ""
echo "========================================"
echo "  Summary — $(hostname)"
echo "========================================"
echo "  Installed: $INSTALLED"
echo "  Skipped:   $SKIPPED  (already present)"
echo "  Failed:    $FAILED"
echo "========================================"
echo ""
if [[ "$FAILED" -gt 0 ]]; then
  echo "  Some packages failed — review output above."
else
  echo "  Next: bash scripts/03-docker.sh"
fi
echo ""
