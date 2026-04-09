# Traefik Router Configuration Guide

**Purpose:** Complete guide for creating, deploying, and managing Traefik HTTP routers for cross-host service routing in the homelab.

**Last Updated:** 2026-04-09  
**Version:** 1.0.0

---

## 🎯 Why Traefik Routers?

### The Problem

You have services running on different hosts:
- **labhost00** (192.168.1.100) - Dozzle, Prometheus, Grafana
- **labhost01** (192.168.1.101) - Kafka UI, Redpanda Console
- **labhost02** (192.168.1.102) - PostgreSQL Admin, other services

Without Traefik, users must remember:
- ❌ Multiple IP addresses (192.168.1.100, .101, .102)
- ❌ Different ports (8080, 9090, 3000, etc.)
- ❌ No HTTPS (insecure connections)
- ❌ Ugly URLs: `http://192.168.1.100:8080`

### The Solution

**Traefik running on labhost01** acts as a reverse proxy, providing:
- ✅ **Pretty URLs:** `https://logs.labhost00.jg-labs.dev`
- ✅ **HTTPS/TLS:** Automatic certificates via Let's Encrypt/Cloudflare
- ✅ **Single Entry Point:** All services via one domain
- ✅ **Cross-Host Routing:** Traefik proxies to services on other hosts
- ✅ **Authentication:** Add SSO (Authentik) later for unified login

### How It Works

```
User requests: https://logs.labhost00.jg-labs.dev
    ↓
DNS resolves to: 192.168.1.101 (labhost01 - where Traefik runs)
    ↓
Traefik reads: router-labhost00-dozzle.yml
    ↓
Proxies to: http://192.168.1.100:8080 (Dozzle on labhost00)
    ↓
User sees: Dozzle via HTTPS with pretty domain
```

**Key Insight:** Traefik doesn't need to be on the same host as the services it routes to. It can proxy across the network using IP addresses.

---

## 🛠️ How to Create a Router for Your New Service

### Step 1: Deploy Your Service

First, get your service running with Docker Compose:

```bash
# Example: Deploy Dozzle on labhost00
cd ~/homelab-observability/01-dozzle
docker-compose up -d

# Verify it's accessible directly
curl http://192.168.1.100:8080  # Should work
```

**Critical:** The service MUST expose its port for Traefik to reach it.

### Step 2: Identify Router Requirements

Gather this information:

| Requirement | Example (Dozzle) | Your Service |
|-------------|------------------|--------------|
| **Service Name** | dozzle | _________ |
| **Host Location** | labhost00 | _________ |
| **Host IP** | 192.168.1.100 | _________ |
| **Service Port** | 8080 | _________ |
| **Desired Domain** | logs.labhost00.jg-labs.dev | _________ |

### Step 3: Create Router File

Navigate to router storage directory:

```bash
cd ~/homelab-observability/traefik-routers
```

Create a new router file using the naming convention:

**Naming Pattern:** `router-{location}-{service}.yml`

```bash
# Example
nano router-labhost00-dozzle.yml
```

**Why this naming?**
- `router-` = Explicit purpose (it's a Traefik router config)
- `labhost00-` = Target host (prevents confusion with same service on different hosts)
- `dozzle` = Service name
- Files get downloaded, shared, moved - name must be self-documenting

### Step 4: Use the Template

Copy this template and customize:

```yaml
# ============================================================================
# Traefik Route: {SERVICE_NAME} on {LOCATION}
# ============================================================================
# Version:       1.0.0
# Last Updated:  YYYY-MM-DD
# Service:       {SERVICE_NAME} - {Brief description}
# Backend:       {location}:{port} (cross-host routing via IP)
# Domain:        {service}.{location}.jg-labs.dev
# Traefik Host:  labhost01 (192.168.1.101)
# Target Host:   {location} ({IP address})
# ============================================================================
# Changelog:
# 1.0.0 (YYYY-MM-DD) - Initial router configuration
#   - Cross-host routing to {IP}:{PORT}
#   - HTTPS via websecure entrypoint
#   - TLS certificate via cloudflare resolver
# ============================================================================
# FILE STORAGE & DEPLOYMENT:
# ============================================================================
# This file is stored in: homelab-observability/traefik-routers/
# 
# Deploy to active Traefik instance by copying to its config directory:
#   Example: /mnt/data/homelab-base/traefik/config/ (if Traefik on labhost01)
# 
# Deployment commands:
#   # Local copy (if on same host)
#   cp ~/homelab-observability/traefik-routers/router-{location}-{service}.yml \
#      /mnt/data/homelab-base/traefik/config/
#   
#   # Remote copy (from workstation or different host)
#   scp ~/homelab-observability/traefik-routers/router-{location}-{service}.yml \
#       labadmin@labhost01:/mnt/data/homelab-base/traefik/config/
# ============================================================================

http:
  # ── Router Configuration ────────────────────────────────────────────────
  routers:
    {service}-{location}:
      # Route incoming requests for this domain
      rule: "Host(\`{service}.{location}.jg-labs.dev\`)"
      
      # Use HTTPS entrypoint (defined in traefik.yml static config)
      entryPoints:
        - websecure
      
      # Link to service backend
      service: {service}-{location}-svc
      
      # TLS configuration
      tls:
        certResolver: cloudflare  # Or letsencrypt, depending on your setup
      
      # Future: Add authentication middleware
      # Uncomment when Authentik SSO is deployed:
      # middlewares:
      #   - authentik@docker
  
  # ── Service Backend ─────────────────────────────────────────────────────
  services:
    {service}-{location}-svc:
      loadBalancer:
        servers:
          # CRITICAL: Use IP address, not container name (cross-host routing)
          - url: "http://{IP_ADDRESS}:{PORT}"
        
        # Optional: Health check to verify target host is reachable
        healthCheck:
          path: /
          interval: 30s
          timeout: 5s

# ============================================================================
# DNS Configuration Required (Cloudflare):
# ============================================================================
# Add this DNS record in Cloudflare:
#   Type: A or CNAME
#   Name: {service}.{location}.jg-labs.dev
#   Value: 192.168.1.101 (labhost01 - where Traefik runs)
#   Proxy: Disabled (DNS only - orange cloud OFF)
#
# Note: Point to Traefik host, NOT the service host!
# ============================================================================
```

### Step 5: Customize for Your Service

Replace all placeholders:

**Example for Dozzle:**
- `{SERVICE_NAME}` → `Dozzle`
- `{location}` → `labhost00`
- `{service}` → `dozzle`
- `{IP_ADDRESS}` → `192.168.1.100`
- `{PORT}` → `8080`

**Result:** `https://logs.labhost00.jg-labs.dev` → `http://192.168.1.100:8080`

### Step 6: Commit to Git

```bash
cd ~/homelab-observability
git add traefik-routers/router-labhost00-dozzle.yml
git commit -m "Add Traefik router for Dozzle on labhost00"
git push
```

Now your router config is version-controlled!

---

## 🚀 How to Deploy the Router

### Deployment Architecture

```
Git Repository (Storage)          Active Traefik (Deployment)
━━━━━━━━━━━━━━━━━━━━━━━━          ━━━━━━━━━━━━━━━━━━━━━━━━━━
homelab-observability/            labhost01 (or wherever)
└── traefik-routers/              └── /mnt/data/.../traefik/config/
    └── router-*.yml     ─────→       └── router-*.yml (copied)
                         COPY
```

### Deployment Steps

**1. Identify Where Traefik is Running**

Currently: labhost01 at `/mnt/data/homelab-base/traefik/config/`

Future: Might move to QNAP, labhost02, etc.

**2. Copy Router File to Traefik Config Directory**

**Option A: Local Copy (if on same host as Traefik)**
```bash
cp ~/homelab-observability/traefik-routers/router-labhost00-dozzle.yml \
   /mnt/data/homelab-base/traefik/config/
```

**Option B: Remote Copy (from different host or workstation)**
```bash
scp ~/homelab-observability/traefik-routers/router-labhost00-dozzle.yml \
    labadmin@192.168.1.101:/mnt/data/homelab-base/traefik/config/
```

**Option C: Copy All Routers at Once**
```bash
# Deploy all labhost00 routers
scp ~/homelab-observability/traefik-routers/router-labhost00-*.yml \
    labadmin@192.168.1.101:/mnt/data/homelab-base/traefik/config/
```

**3. Traefik Auto-Detects the New Route**

Traefik's file provider watches the config directory. It automatically:
- ✅ Detects new `.yml` files
- ✅ Loads the routing rules
- ✅ Starts proxying requests
- ✅ No restart required!

**4. Verify in Traefik Dashboard**

Check Traefik dashboard (usually at `http://traefik.labhost01.jg-labs.dev:8080`):
- Routers tab → Should see `dozzle-labhost00`
- Services tab → Should see `dozzle-labhost00-svc`
- Status should be green

**5. Test the Route**

```bash
# Test DNS resolution
nslookup logs.labhost00.jg-labs.dev
# Should resolve to 192.168.1.101 (Traefik host)

# Test HTTP access (if HTTPS not ready yet)
curl http://logs.labhost00.jg-labs.dev

# Test HTTPS access (final test)
curl https://logs.labhost00.jg-labs.dev
# OR visit in browser
```

---

## 📛 File Naming Convention

### Pattern

`router-{location}-{service}.yml`

### Components

**`router-`** (Prefix)
- Makes purpose explicit
- Clear even when file is downloaded, shared, or moved
- Not redundant - directory path isn't always available

**`{location}-`** (Host identifier)
- Where the service runs (labhost00, labhost01, labhost02)
- Prevents collision when same service on multiple hosts
- Enables sorting by location

**`{service}`** (Service name)
- The actual service being routed
- Use lowercase, kebab-case for multi-word (e.g., `uptime-kuma`)

### Examples

```
router-labhost00-dozzle.yml           # Dozzle on labhost00
router-labhost00-prometheus.yml       # Prometheus on labhost00
router-labhost00-grafana.yml          # Grafana on labhost00
router-labhost00-uptime-kuma.yml      # Uptime Kuma on labhost00
router-labhost01-kafka-ui.yml         # Kafka UI on labhost01
router-labhost02-postgres-admin.yml   # PostgreSQL Admin on labhost02
```

### Why This Matters

Files have a lifecycle beyond their original directory:
- Downloaded to `~/Downloads/`
- Shared via WhatsApp, Slack, email
- Attached to support tickets
- Copied to temporary directories

The filename must be **self-documenting** independent of location.

---

## 📋 Configuration Checklist

When creating a new router, verify:

- [ ] Service is running and accessible via `http://{IP}:{PORT}`
- [ ] Router file follows naming convention: `router-{location}-{service}.yml`
- [ ] Header includes version, changelog, and deployment instructions
- [ ] Router name is `{service}-{location}` (e.g., `dozzle-labhost00`)
- [ ] Domain rule uses correct format: `{service}.{location}.jg-labs.dev`
- [ ] Backend URL uses **IP address** not container name
- [ ] TLS/certResolver configured correctly
- [ ] DNS record points to **Traefik host** (192.168.1.101), not service host
- [ ] File committed to git
- [ ] File deployed to active Traefik instance
- [ ] Route appears in Traefik dashboard
- [ ] Service accessible via HTTPS domain

---

## 🔧 Common Issues & Troubleshooting

### Issue: "502 Bad Gateway"

**Cause:** Traefik can't reach the backend service.

**Debug:**
```bash
# On Traefik host (labhost01), test connectivity
curl http://192.168.1.100:8080  # Replace with your service IP:PORT

# Check if port is actually exposed
docker ps | grep dozzle  # Should show 8080:8080 mapping
```

**Fix:**
- Ensure service is running: `docker-compose ps`
- Ensure port is exposed in docker-compose.yml
- Check firewall rules (unlikely on local network)

---

### Issue: "404 Not Found - No matching route"

**Cause:** DNS domain doesn't match router rule, or router not loaded.

**Debug:**
```bash
# Check DNS is pointing to Traefik host
nslookup logs.labhost00.jg-labs.dev
# Should return 192.168.1.101 (Traefik host)

# Check Traefik dashboard - is router loaded?
# Visit http://192.168.1.101:8080 (Traefik dashboard)
```

**Fix:**
- Verify DNS record points to Traefik host (NOT service host)
- Check router file exists in Traefik config directory
- Check for YAML syntax errors: `docker-compose -f router-file.yml config`
- Restart Traefik if file provider isn't watching: `docker restart traefik`

---

### Issue: Certificate/TLS Errors

**Cause:** certResolver misconfigured or Let's Encrypt rate limit.

**Debug:**
```bash
# Check Traefik logs
docker logs traefik | grep -i certificate
```

**Fix:**
- Verify certResolver name matches Traefik static config
- Check Cloudflare API credentials (if using Cloudflare DNS challenge)
- Use staging Let's Encrypt first to avoid rate limits

---

## 🎯 Quick Reference

### Create Router
```bash
cd ~/homelab-observability/traefik-routers
nano router-labhost00-servicename.yml
# Use template, customize, save
git add . && git commit -m "Add router for servicename" && git push
```

### Deploy Router
```bash
scp router-labhost00-servicename.yml \
    labadmin@192.168.1.101:/mnt/data/homelab-base/traefik/config/
```

### Test Router
```bash
curl https://servicename.labhost00.jg-labs.dev
```

### Update Router
```bash
# Edit file in repo
nano traefik-routers/router-labhost00-servicename.yml
git commit -am "Update router config"
# Re-deploy
scp router-labhost00-servicename.yml labadmin@192.168.1.101:/mnt/.../traefik/config/
# Traefik auto-reloads
```

---

## 🔄 Migration Scenarios

### Scenario: Move Traefik to Different Host

**Example:** Traefik moves from labhost01 → QNAP

```bash
# 1. Copy routers to new Traefik host
scp ~/homelab-observability/traefik-routers/*.yml \
    admin@qnap:/Container/traefik/config/

# 2. Update DNS (all domains still point to new Traefik location)
# Change: *.labhost00.jg-labs.dev → QNAP IP

# 3. No changes to router files needed!
```

**Key Point:** Router files are portable - they work anywhere Traefik runs.

---

## 📖 Related Documentation

- [Docker Compose Checklist](./DOCKER-COMPOSE-CHECKLIST.md) - Service deployment standards
- [Port Assignments](./PORTS.md) - Reserved ports per tool
- [Traefik Routers README](../traefik-routers/README.md) - Router storage workflow

---

**This guide is the single source of truth for Traefik router creation and deployment across the homelab.**
