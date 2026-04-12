#!/bin/bash
# ============================================================================
# Wazuh Certificate Fix Script
# ============================================================================
# Fixes two issues:
# 1. Certificates missing DNS names (causing manager SSL errors)
# 2. Dashboard looking for certs in wrong location
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

section() { echo -e "\n${BLUE}══════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════════${NC}\n"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

section "Step 1: Stop Current Deployment"
docker compose down
ok "Containers stopped"

section "Step 2: Backup Old Certificates"
if [ -d "certs" ]; then
    mv certs certs.backup.$(date +%Y%m%d_%H%M%S)
    ok "Old certificates backed up"
fi

section "Step 3: Backup Old certs.yml"
if [ -f "certs.yml" ]; then
    cp certs.yml certs.yml.backup
    ok "Old certs.yml backed up"
fi

section "Step 4: Update certs.yml with DNS Names"
cat > certs.yml << 'EOF'
# ============================================================================
# Wazuh Certificate Configuration
# ============================================================================
# DNS names MUST match docker-compose service names for SSL validation
# ============================================================================

nodes:
  # Wazuh indexer nodes
  indexer:
    - name: node-1
      ip: 
        - 127.0.0.1
      dns:
        - wazuh-indexer      # Docker service name (CRITICAL)
        - wazuh.indexer      # Alternative format
        - node-1             # Certificate filename compatibility
  
  # Wazuh server nodes
  server:
    - name: wazuh-1
      ip:
        - 127.0.0.1
      dns:
        - wazuh-manager      # Docker service name (CRITICAL)
        - wazuh.manager      # Alternative format
        - wazuh-1            # Certificate filename compatibility
  
  # Wazuh dashboard nodes
  dashboard:
    - name: dashboard
      ip:
        - 127.0.0.1
      dns:
        - wazuh-dashboard    # Docker service name (CRITICAL)
        - wazuh.dashboard    # Alternative format
        - dashboard          # Certificate filename compatibility
EOF
ok "certs.yml updated with DNS names"

section "Step 5: Regenerate Certificates"
docker compose -f generate-certs.yml run --rm generator
ok "New certificates generated"

section "Step 6: Rename Certificates to Standard Names"
cd certs
cp node-1.pem wazuh.indexer.pem
cp node-1-key.pem wazuh.indexer.key
cp wazuh-1.pem wazuh.manager.pem
cp wazuh-1-key.pem wazuh.manager.key
cp dashboard.pem wazuh.dashboard.pem
cp dashboard-key.pem wazuh.dashboard.key
cd ..
ok "Certificates renamed"

section "Step 7: Verify Certificate DNS Names"
info "Checking indexer certificate..."
openssl x509 -in certs/wazuh.indexer.pem -noout -text | grep -A3 "Subject Alternative Name"

section "Step 8: Fix Dashboard Certificate Paths in docker-compose.yml"
warn "Manual step required: Update docker-compose.yml"
cat << 'EOF'

In your docker-compose.yml, find the wazuh-dashboard volumes section and change:

FROM (incorrect):
      - ./certs/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem:ro
      - ./certs/wazuh.dashboard.key:/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem:ro
      - ./certs/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem:ro

TO (correct):
      - ./certs/wazuh.dashboard.pem:/etc/wazuh-dashboard/certs/dashboard.pem:ro
      - ./certs/wazuh.dashboard.key:/etc/wazuh-dashboard/certs/dashboard-key.pem:ro
      - ./certs/root-ca.pem:/etc/wazuh-dashboard/certs/root-ca.pem:ro

EOF

read -p "Press Enter after you've updated docker-compose.yml..."

section "Step 9: Deploy with New Certificates"
docker compose up -d
ok "Deployment started"

section "Step 10: Monitor Logs"
info "Waiting 10 seconds for services to start..."
sleep 10

echo ""
info "Checking indexer logs for 'Node started'..."
docker compose logs wazuh-indexer | grep -i "node started" || warn "Indexer may still be starting"

echo ""
info "Checking manager logs for SSL errors..."
docker compose logs wazuh-manager | tail -20

echo ""
info "Checking dashboard logs for errors..."
docker compose logs wazuh-dashboard | tail -20

section "Deployment Complete"
info "Check full logs with: docker compose logs -f"
info "Check status with: docker compose ps"
