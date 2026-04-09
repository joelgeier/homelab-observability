# Docker Compose Refactoring Checklist

**Purpose:** Systematic checklist for converting reference docker-compose files from online sources into standardized homelab-observability stack configurations.

**Usage:** Check each item before declaring a compose file "deployment ready."

---

## 📋 Pre-Flight Questions

Before starting, answer these:

- [ ] **Tool name:** _____________
- [ ] **Reference source URL:** _____________
- [ ] **Data persistence needed?** Yes / No
- [ ] **External access required?** Yes / No (affects port exposure)
- [ ] **Traefik reverse proxy?** Yes / No
- [ ] **Dependencies?** (Other services this depends on)

---

## 🔧 Network Configuration

- [ ] **Remove default network** - Delete any `networks:` section at container level if using default
- [ ] **Create custom network** (optional) - Add network definition if isolating this stack
  ```yaml
  networks:
    toolname_network:
      driver: bridge
  ```
- [ ] **Verify network driver** - Use `bridge` for single-host deployments

---

## 🔌 Port Mapping

- [ ] **Review port conflicts** - Check against `docs/PORTS.md`
- [ ] **Update PORTS.md** - Add new port assignments
- [ ] **Use host mode sparingly** - Only if absolutely required (prefer bridge + published ports)
- [ ] **Format consistency** - Use `"HOST:CONTAINER"` format (quoted for clarity)
- [ ] **Comment port purpose** - Add inline comment explaining each port
  ```yaml
  ports:
    - "9000:9000"  # Web UI
    - "9001:9001"  # Agent communication
  ```

---

## 💾 Volume Mounts

- [ ] **Use ${DATA_ROOT} variable** - Never hardcode `/mnt/data/homelab-observability`
- [ ] **Create volume subdirectory** - Follow pattern: `${DATA_ROOT}/toolname/`
- [ ] **Named volumes vs bind mounts** - Prefer bind mounts for observability (easier backup)
- [ ] **Document volume purpose** - Add comments explaining what each volume stores
  ```yaml
  volumes:
    - ${DATA_ROOT}/prometheus/data:/prometheus              # Time-series metrics storage
    - ${DATA_ROOT}/prometheus/config:/etc/prometheus/config # Scrape configs
  ```
- [ ] **Set proper permissions** - Note if volumes need specific ownership/permissions
- [ ] **Verify paths exist** - Document if directories need pre-creation

---

## 🏷️ Container Configuration

- [ ] **Container naming** - Use format: `projectname-toolname` (e.g., `observability-prometheus`)
  ```yaml
  container_name: observability-prometheus
  ```
- [ ] **Image tags** - Use specific version tags, not `latest`
  ```yaml
  image: prom/prometheus:v2.50.0  # NOT prom/prometheus:latest
  ```
- [ ] **Restart policy** - Set to `unless-stopped` for production
  ```yaml
  restart: unless-stopped
  ```
- [ ] **Resource limits** (optional) - Add if tool is resource-heavy
  ```yaml
  deploy:
    resources:
      limits:
        memory: 2G
      reservations:
        memory: 512M
  ```

---

## 🌐 Traefik Labels (If Using Reverse Proxy)

- [ ] **Enable Traefik** - Add `traefik.enable=true`
- [ ] **HTTP router** - Define router name and rule
  ```yaml
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.prometheus.rule=Host(`prometheus.labhost00.jg-labs.dev`)"
    - "traefik.http.routers.prometheus.entrypoints=web"
    - "traefik.http.services.prometheus.loadbalancer.server.port=9090"
  ```
- [ ] **HTTPS/TLS** - Add if using Let's Encrypt
- [ ] **Middleware** - Add authentication if needed (BasicAuth, OAuth)
- [ ] **Network** - Ensure container is on Traefik network

---

## 🔐 Environment Variables

- [ ] **Extract to .env** - Move all configurable values to `.env` file
  ```yaml
  environment:
    - ADMIN_USER=${PROMETHEUS_ADMIN_USER}
    - ADMIN_PASSWORD=${PROMETHEUS_ADMIN_PASSWORD}
  ```
- [ ] **Update .env.example** - Add new variables with descriptions
  ```bash
  # Prometheus Configuration
  PROMETHEUS_ADMIN_USER=admin
  PROMETHEUS_ADMIN_PASSWORD=changeme
  PROMETHEUS_RETENTION_TIME=30d
  ```
- [ ] **Sensitive data** - Never commit secrets to git (use .env, not hardcoded)
- [ ] **Default values** - Provide sensible defaults in .env.example

---

## 📝 Documentation & Comments

- [ ] **File header block** - Add standard header
  ```yaml
  # ============================================================================
  # Tool Name - Brief Description
  # ============================================================================
  # Purpose:       What this tool does
  # Web UI:        http://labhost00:PORT
  # Data Location: ${DATA_ROOT}/toolname/
  # Dependencies:  List any required services
  # Documentation: Link to official docs
  # ============================================================================
  ```
- [ ] **Section comments** - Organize file with section headers
  ```yaml
  # ── Service Configuration ─────────────────────────────────────
  # ── Volume Mounts ─────────────────────────────────────────────
  # ── Network Configuration ─────────────────────────────────────
  ```
- [ ] **Inline comments** - Explain non-obvious configurations
- [ ] **Create README.md** - Add tool-specific README in tool directory
  ```
  /toolname/
  ├── docker-compose.yml
  ├── README.md              # Deployment guide
  └── config/                # Configuration files
  ```

---

## 🔍 Health Checks

- [ ] **Add healthcheck** - Define container health check (if supported)
  ```yaml
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
  ```
- [ ] **Dependency ordering** - Use `depends_on` with conditions
  ```yaml
  depends_on:
    prometheus:
      condition: service_healthy
  ```

---

## 🧪 Testing & Validation

- [ ] **Syntax validation** - Run `docker-compose config` to validate YAML
- [ ] **Dry run** - Test with `docker-compose up --no-start`
- [ ] **Port conflicts** - Verify no port collisions with `netstat -tuln`
- [ ] **Volume creation** - Check if data directories were created
- [ ] **Container logs** - Review logs after first start: `docker-compose logs -f`
- [ ] **Web UI access** - Confirm UI is accessible at expected URL
- [ ] **Data persistence** - Stop/start container, verify data survives

---

## 📦 Stack Integration

- [ ] **Add to main README** - Update project README with tool info
- [ ] **Update PORTS.md** - Document all exposed ports
- [ ] **Phase assignment** - Note which deployment phase this belongs to
- [ ] **Monitoring integration** - Plan Prometheus exporters (if applicable)
- [ ] **Backup inclusion** - Ensure data directories are in backup scope

---

## 🚀 Deployment Readiness

**Final checks before `docker-compose up -d`:**

- [ ] All checklist items above completed
- [ ] `.env` file created and configured
- [ ] Data directories exist (if pre-creation required)
- [ ] No port conflicts
- [ ] Documentation complete (README.md)
- [ ] Compose file committed to git
- [ ] Team review completed (if applicable)

---

## 📋 Quick Reference Template

```yaml
# ============================================================================
# Tool Name - Brief Description
# ============================================================================
# Purpose:       
# Web UI:        http://labhost00:PORT
# Data Location: ${DATA_ROOT}/toolname/
# Dependencies:  
# Documentation: 
# ============================================================================

services:
  toolname:
    image: namespace/toolname:version
    container_name: observability-toolname
    restart: unless-stopped
    
    # ── Ports ─────────────────────────────────────────────────
    ports:
      - "PORT:PORT"  # Purpose
    
    # ── Volumes ───────────────────────────────────────────────
    volumes:
      - ${DATA_ROOT}/toolname/data:/data          # Data storage
      - ${DATA_ROOT}/toolname/config:/config      # Configuration
    
    # ── Environment ───────────────────────────────────────────
    environment:
      - VARIABLE=${ENV_VAR}
    
    # ── Health Check ──────────────────────────────────────────
    healthcheck:
      test: ["CMD", "command"]
      interval: 30s
      timeout: 10s
      retries: 3
    
    # ── Networks ──────────────────────────────────────────────
    # networks:
    #   - toolname_network

# networks:
#   toolname_network:
#     driver: bridge
```

---

## 🎯 Common Gotchas

**Watch out for:**
- ❌ Using `latest` tag - Always pin versions
- ❌ Hardcoded paths - Use `${DATA_ROOT}` variable
- ❌ Missing restart policy - Containers won't survive reboot
- ❌ No health checks - Can't detect silent failures
- ❌ Exposed unnecessary ports - Security risk
- ❌ Missing volume backups - Data loss risk
- ❌ No resource limits - One container can starve others
- ❌ Traefik labels on non-Traefik networks - Won't work

---

**Last Updated:** 2026-04-09  
**Maintainer:** labadmin  
**Version:** 1.0
