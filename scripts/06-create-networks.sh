#!/usr/bin/env bash
# ============================================================================
# 06-create-networks.sh - Docker Network Setup for Observability Stack
# ============================================================================
# Version:       1.0.0
# Last Updated:  2026-04-09
# Purpose:       Create shared Docker networks for observability tools
# Run As:        labadmin (sudo not required for Docker commands)
# Dependencies:  Docker installed and running (03-docker.sh)
# ============================================================================
# Creates the shared "observability" Docker bridge network that all
# observability tools will join. This allows inter-container communication
# (Prometheus scraping Grafana, Grafana querying Prometheus, etc.)
#
# Network is created ONCE, referenced by all docker-compose.yml files as:
#   networks:
#     observability:
#       external: true
#
# This script is idempotent - safe to run multiple times.
# ============================================================================

set -euo pipefail

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
  error "Run as labadmin - Docker commands work without sudo (docker group)"
  exit 1
fi

# ── Docker Check ────────────────────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
  error "Docker not found - run 03-docker.sh first"
  exit 1
fi

if ! docker info &> /dev/null; then
  error "Docker daemon not running or user not in docker group"
  error "Try: sudo usermod -aG docker $USER && newgrp docker"
  exit 1
fi

# ── Banner ──────────────────────────────────────────────────────────────────
section "Homelab Observability - Docker Network Setup"
info "Creating shared network for observability stack"
echo ""

# ── Network Configuration ───────────────────────────────────────────────────
NETWORK_NAME="observability"
DRIVER="bridge"

# ── Check if Network Already Exists ─────────────────────────────────────────
section "Network: $NETWORK_NAME"

if docker network inspect "$NETWORK_NAME" &> /dev/null; then
  ok "Network already exists: $NETWORK_NAME"
  info "Network details:"
  docker network inspect "$NETWORK_NAME" --format '  Driver: {{.Driver}}'
  docker network inspect "$NETWORK_NAME" --format '  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
  docker network inspect "$NETWORK_NAME" --format '  Gateway: {{range .IPAM.Config}}{{.Gateway}}{{end}}'
  
  # Show connected containers (if any)
  CONTAINERS=$(docker network inspect "$NETWORK_NAME" --format '{{range .Containers}}{{.Name}} {{end}}')
  if [[ -n "$CONTAINERS" ]]; then
    info "Connected containers: $CONTAINERS"
  else
    info "Connected containers: (none yet)"
  fi
  
else
  info "Creating network: $NETWORK_NAME"
  docker network create \
    --driver "$DRIVER" \
    "$NETWORK_NAME"
  
  ok "Network created: $NETWORK_NAME"
  info "Driver: $DRIVER"
  info "All observability tools will join this network"
fi

# ── Verification ────────────────────────────────────────────────────────────
section "Verification"

# List all networks
info "All Docker networks:"
docker network ls

echo ""

# ── Summary ─────────────────────────────────────────────────────────────────
section "Summary"

ok "Network ready: $NETWORK_NAME"
ok "Docker-compose files should reference this as 'external: true'"

echo ""
info "Next steps:"
info "  1. Deploy tools using docker-compose in homelab-observability/"
info "  2. Each compose file will join this network automatically"
info "  3. Containers can reach each other by name (e.g., http://prometheus:9090)"

# ── Usage Example ───────────────────────────────────────────────────────────
cat << 'EOF'

────────────────────────────────────────────────────────────────────────────
DOCKER-COMPOSE.YML EXAMPLE:
────────────────────────────────────────────────────────────────────────────
services:
  prometheus:
    image: prom/prometheus:latest
    networks:
      - observability

networks:
  observability:
    external: true  # References the network created by this script
────────────────────────────────────────────────────────────────────────────
INTER-CONTAINER COMMUNICATION:
────────────────────────────────────────────────────────────────────────────
From Grafana container, reach Prometheus:
  http://prometheus:9090

From Prometheus container, scrape Grafana metrics:
  http://grafana:3000/metrics

Container names resolve via Docker's built-in DNS!
────────────────────────────────────────────────────────────────────────────
EOF

echo ""
exit 0
