#!/bin/bash
# ============================================================================
# Wazuh v1.3.0 - Deployment Preparation Script
# ============================================================================
# Prepares certificates and config files for Wazuh deployment
# Run this BEFORE docker compose up
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
section() { echo -e "\n${BLUE}══════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════════${NC}\n"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# ============================================================================
# Step 1: Verify Prerequisites
# ============================================================================
section "Step 1: Verify Prerequisites"

# Check if certs directory exists
if [ ! -d "certs" ]; then
    error "Certificates not found!"
    info "Run: docker compose -f generate-certs.yml run --rm generator"
    exit 1
fi
ok "Certificates directory exists"

# Check if required certs exist
REQUIRED_CERTS=("node-1.pem" "node-1-key.pem" "wazuh-1.pem" "wazuh-1-key.pem" "dashboard.pem" "dashboard-key.pem" "root-ca.pem" "admin.pem" "admin-key.pem")
for cert in "${REQUIRED_CERTS[@]}"; do
    if [ ! -f "certs/$cert" ]; then
        error "Missing certificate: certs/$cert"
        exit 1
    fi
done
ok "All required certificates present"

# ============================================================================
# Step 2: Rename Certificates to Official Pattern
# ============================================================================
section "Step 2: Rename Certificates to Match Official Pattern"

cd certs

# Indexer certificates
if [ ! -f "wazuh.indexer.pem" ] || [ "node-1.pem" -nt "wazuh.indexer.pem" ]; then
    cp node-1.pem wazuh.indexer.pem
    ok "Created wazuh.indexer.pem"
else
    info "wazuh.indexer.pem already exists"
fi

if [ ! -f "wazuh.indexer.key" ] || [ "node-1-key.pem" -nt "wazuh.indexer.key" ]; then
    cp node-1-key.pem wazuh.indexer.key
    ok "Created wazuh.indexer.key"
else
    info "wazuh.indexer.key already exists"
fi

# Manager certificates
if [ ! -f "wazuh.manager.pem" ] || [ "wazuh-1.pem" -nt "wazuh.manager.pem" ]; then
    cp wazuh-1.pem wazuh.manager.pem
    ok "Created wazuh.manager.pem"
else
    info "wazuh.manager.pem already exists"
fi

if [ ! -f "wazuh.manager.key" ] || [ "wazuh-1-key.pem" -nt "wazuh.manager.key" ]; then
    cp wazuh-1-key.pem wazuh.manager.key
    ok "Created wazuh.manager.key"
else
    info "wazuh.manager.key already exists"
fi

# Dashboard certificates
if [ ! -f "wazuh.dashboard.pem" ] || [ "dashboard.pem" -nt "wazuh.dashboard.pem" ]; then
    cp dashboard.pem wazuh.dashboard.pem
    ok "Created wazuh.dashboard.pem"
else
    info "wazuh.dashboard.pem already exists"
fi

if [ ! -f "wazuh.dashboard.key" ] || [ "dashboard-key.pem" -nt "wazuh.dashboard.key" ]; then
    cp dashboard-key.pem wazuh.dashboard.key
    ok "Created wazuh.dashboard.key"
else
    info "wazuh.dashboard.key already exists"
fi

cd ..

# ============================================================================
# Step 3: Verify Certificate Filenames
# ============================================================================
section "Step 3: Verify Certificate Filenames"

info "Certificate inventory:"
ls -lh certs/*.pem certs/*.key | grep -E "wazuh\.(indexer|manager|dashboard|root-ca|admin)" || true

# ============================================================================
# Step 4: Prepare Config Directory
# ============================================================================
section "Step 4: Prepare Config Directory"

mkdir -p config
ok "Config directory created"

# Check if opensearch.yml exists
if [ ! -f "config/opensearch.yml" ]; then
    if [ -f "official-opensearch.yml" ]; then
        cp official-opensearch.yml config/opensearch.yml
        ok "Copied official opensearch.yml to config/"
    else
        warn "official-opensearch.yml not found"
        info "Downloading from official repo..."
        curl -s https://raw.githubusercontent.com/wazuh/wazuh-docker/v4.11.2/single-node/config/wazuh_indexer/wazuh.indexer.yml -o config/opensearch.yml
        ok "Downloaded opensearch.yml"
    fi
else
    ok "config/opensearch.yml already exists"
fi

# ============================================================================
# Step 5: Final Checklist
# ============================================================================
section "Step 5: Final Checklist"

CHECKLIST=(
    "certs/wazuh.indexer.pem:Indexer certificate"
    "certs/wazuh.indexer.key:Indexer key"
    "certs/wazuh.manager.pem:Manager certificate"
    "certs/wazuh.manager.key:Manager key"
    "certs/wazuh.dashboard.pem:Dashboard certificate"
    "certs/wazuh.dashboard.key:Dashboard key"
    "certs/root-ca.pem:Root CA"
    "certs/admin.pem:Admin certificate"
    "certs/admin-key.pem:Admin key"
    "config/opensearch.yml:OpenSearch config"
)

ALL_OK=true
for item in "${CHECKLIST[@]}"; do
    IFS=':' read -r file desc <<< "$item"
    if [ -f "$file" ]; then
        ok "$desc: $file"
    else
        error "$desc: $file (MISSING)"
        ALL_OK=false
    fi
done

# ============================================================================
# Summary
# ============================================================================
section "Preparation Summary"

if [ "$ALL_OK" = true ]; then
    ok "All prerequisites satisfied!"
    echo ""
    info "Ready to deploy. Run:"
    echo -e "  ${GREEN}docker compose up -d${NC}"
    echo ""
    info "Monitor startup with:"
    echo -e "  ${GREEN}docker compose logs -f wazuh-indexer${NC}"
    exit 0
else
    error "Some files are missing. Please resolve the issues above."
    exit 1
fi
