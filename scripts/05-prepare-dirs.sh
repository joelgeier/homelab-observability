#!/usr/bin/env bash
# ============================================================================
# 05-prepare-dirs.sh - Observability Data Directory Structure
# ============================================================================
# Version:       1.0.0
# Last Updated:  2026-04-09
# Purpose:       Create directory structure for observability tools data
# Run As:        labadmin (sudo will be used when needed)
# Dependencies:  None (run after 03-docker.sh and 04-tailscale.sh)
# ============================================================================
# This script creates the persistent data directory structure for observability
# tools. Each tool stores configuration, data, and logs in dedicated
# subdirectories under /mnt/data/homelab-observability/
#
# ITERATIVE APPROACH:
# We add directories as we build each tool. This script will be updated
# as we deploy more tools. Current structure reflects only deployed tools.
#
# Current Directory Structure:
#   /mnt/data/homelab-observability/
#   ├── wazuh/
#   │   ├── indexer-config/  (optional opensearch.yml customization)
#   │   ├── manager-config/  (custom rules, decoders)
#   │   └── dashboard-config/ (optional dashboard customization)
#   └── [future tools added as we deploy them]/
#
# NOTE: Most Wazuh data is stored in Docker named volumes (managed by Docker).
# These directories are ONLY for optional custom configuration files.
# ============================================================================

set -euo pipefail

# ── Configuration ───────────────────────────────────────────────────────────
DATA_ROOT="/mnt/data/homelab-observability"
USER="${USER:-labadmin}"
GROUP="${GROUP:-labadmin}"

# ── Color Output ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}ℹ${NC}  $*"; }
ok()    { echo -e "${GREEN}✓${NC}  $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC}  $*" >&2; }
section() { echo ""; echo -e "${BLUE}━━━ $* ━━━${NC}"; }

# ── Root Check ──────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  error "Do NOT run this script as root"
  error "Run as labadmin - script will use sudo when needed"
  exit 1
fi

# ── Banner ──────────────────────────────────────────────────────────────────
section "Homelab Observability - Directory Preparation"
info "Creating data directory structure under: $DATA_ROOT"
info "Owner: $USER:$GROUP"
echo ""

# ── Create Base Directory ───────────────────────────────────────────────────
section "Base directory"

if [[ -d "$DATA_ROOT" ]]; then
  ok "Base directory already exists: $DATA_ROOT"
else
  info "Creating base directory: $DATA_ROOT"
  sudo mkdir -p "$DATA_ROOT"
  sudo chown "$USER:$GROUP" "$DATA_ROOT"
  sudo chmod 755 "$DATA_ROOT"
  ok "Base directory created"
fi

# ══════════════════════════════════════════════════════════════════════════
# DEPLOYED TOOLS - Add sections here as we deploy each tool
# ══════════════════════════════════════════════════════════════════════════

# ── Wazuh (Phase IV - Security Monitoring) ──────────────────────────────────
section "Wazuh - Security Monitoring (Phase IV)"

info "Creating Wazuh configuration directories..."
mkdir -p "$DATA_ROOT/wazuh/indexer-config"
mkdir -p "$DATA_ROOT/wazuh/manager-config"
mkdir -p "$DATA_ROOT/wazuh/dashboard-config"

ok "Wazuh: indexer-config/, manager-config/, dashboard-config/"

warn "Note: Wazuh core data (indices, logs, agent keys) stored in Docker volumes"
info "      These directories are ONLY for optional custom configurations"

# ══════════════════════════════════════════════════════════════════════════
# FUTURE TOOLS - Will be added here as we deploy them
# ══════════════════════════════════════════════════════════════════════════
# Uncomment and customize as we add each tool:
#
# # ── Prometheus (Phase II - Metrics) ──────────────────────────────────────
# section "Prometheus - Metrics Collection (Phase II)"
# mkdir -p "$DATA_ROOT/prometheus/config"
# mkdir -p "$DATA_ROOT/prometheus/data"
# sudo chown -R 65534:65534 "$DATA_ROOT/prometheus/data"  # UID for nobody
# ok "Prometheus: config/, data/ (UID 65534)"
#
# # ── Grafana (Phase II - Visualization) ───────────────────────────────────
# section "Grafana - Dashboards (Phase II)"
# mkdir -p "$DATA_ROOT/grafana/config"
# mkdir -p "$DATA_ROOT/grafana/data"
# mkdir -p "$DATA_ROOT/grafana/logs"
# sudo chown -R 472:472 "$DATA_ROOT/grafana/data"  # UID for grafana
# sudo chown -R 472:472 "$DATA_ROOT/grafana/logs"
# ok "Grafana: config/, data/, logs/ (UID 472)"
#
# Add more tools here as we deploy them...
# ══════════════════════════════════════════════════════════════════════════

# ── Verify Directory Structure ──────────────────────────────────────────────
section "Verification"

info "Current directory structure:"
if command -v tree &> /dev/null; then
  tree -L 3 -F "$DATA_ROOT"
else
  warn "tree command not installed - using ls instead"
  ls -lah "$DATA_ROOT"
  for dir in "$DATA_ROOT"/*; do
    if [[ -d "$dir" ]]; then
      echo ""
      echo "$(basename "$dir")/"
      ls -lh "$dir"
    fi
  done
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
section "Summary"

ok "Data root:     $DATA_ROOT"
ok "Owner:         $USER:$GROUP"
ok "Tools ready:   Wazuh (custom config directories)"

echo ""
info "As we deploy more tools, rerun this script to add their directories"
info "Next: Deploy Wazuh using docker-compose in 08-wazuh/"
echo ""

# ── Notes ───────────────────────────────────────────────────────────────────
cat << 'EOF'
────────────────────────────────────────────────────────────────────────────
DIRECTORY STRATEGY:
────────────────────────────────────────────────────────────────────────────
1. Docker Volumes vs Directory Mounts:
   - Named volumes (Docker-managed): Core application data
   - Directory mounts (this script): Custom configs, optional overrides

2. Wazuh Example:
   - Docker volumes: /var/lib/wazuh-indexer, /var/ossec/data, etc.
   - Directory mounts: Custom rules (manager-config/local_rules.xml)

3. Why Iterative:
   - Discover actual requirements as we build each tool
   - Some tools need special UIDs/GIDs (e.g., Grafana = 472)
   - Avoid guessing permissions - learn from deployment experience

4. Rerun Safety:
   - This script is idempotent - safe to run multiple times
   - mkdir -p won't fail if directories exist
   - We'll add new sections as we deploy more tools
────────────────────────────────────────────────────────────────────────────
EOF

echo ""
exit 0
