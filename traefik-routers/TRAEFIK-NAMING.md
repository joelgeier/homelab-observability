# Traefik Router File Naming Convention

**Established:** 2026-04-09  
**Pattern:** `router-{location}-{service}.yml`

---

## 📛 Naming Pattern

**Format:** `router-labhost0X-servicename.yml`

**Rationale:**
Files get downloaded, shared, and moved out of their original directory context. The filename must be self-documenting independent of its location on the filesystem.

---

## ✅ Examples

```
router-labhost00-dozzle.yml
router-labhost00-prometheus.yml
router-labhost00-grafana.yml
router-labhost00-uptime-kuma.yml
router-labhost01-kafka-ui.yml
router-labhost01-redpanda-console.yml
router-labhost02-postgres-admin.yml
```

---

## 🏗️ Structure Breakdown

**`router-`** 
- Explicit purpose (Traefik HTTP router config)
- Clear even in Downloads folder or WhatsApp share
- Not redundant - directory path can't always describe context

**`labhost0X-`**
- Target host where service runs
- Prevents collision when same service runs on multiple hosts
- Enables alphabetical sorting by location

**`servicename`**
- The actual service being routed
- Use kebab-case for multi-word services (e.g., `uptime-kuma`)

**`.yml`**
- Traefik dynamic configuration format

---

## 🗂️ File Location

These router files live on **labhost01** (where Traefik runs):

```
/mnt/data/homelab-base/traefik/config/
├── router-labhost00-dozzle.yml
├── router-labhost00-prometheus.yml
├── router-labhost00-grafana.yml
├── router-labhost01-kafka-ui.yml
└── router-labhost02-postgres.yml
```

Even though they live in the `/traefik/config/` directory, the `router-` prefix ensures clarity when files are:
- Downloaded to temporary folders
- Shared via messaging apps
- Attached to support tickets
- Copied to documentation

---

## ❌ Anti-Patterns (Don't Use)

### Too Short
```
dozzle.yml                    # What host? What purpose?
labhost00-dozzle.yml          # Is this a router? A compose file?
```

### Too Long
```
traefik-router-labhost00-dozzle.yml   # Redundant 'traefik' prefix
```

### Ambiguous
```
dozzle-router.yml             # Which host?
logs.yml                      # Which service? Which host?
```

---

## 🎯 Benefits

1. **Self-Documenting** - Filename tells complete story
2. **Collision-Proof** - Location prefix prevents duplicates
3. **Sortable** - Alphabetical by host, then service
4. **Shareable** - Clear meaning outside directory context
5. **Scannable** - Consistent pattern aids visual parsing

---

## 📝 Template

When creating a new Traefik router file:

```yaml
# ============================================================================
# Traefik Route: {Service Name} on {Location}
# ============================================================================
# Version:       1.0.0
# Last Updated:  YYYY-MM-DD
# Service:       {Service Name} - {Brief Description}
# Backend:       {location}:{port} (cross-host routing via IP)
# Domain:        {service}.{location}.jg-labs.dev
# Traefik Host:  labhost01 (192.168.1.101)
# Target Host:   {location} ({IP address})
# ============================================================================
# Filename:      router-{location}-{service}.yml
# File Location: /mnt/data/homelab-base/traefik/config/ (on labhost01)
# ============================================================================

http:
  routers:
    {service}-{location}:
      rule: "Host(`{service}.{location}.jg-labs.dev`)"
      # ... rest of config
```

---

## 🔄 Applying to Existing Files

If you have existing router files without this convention:

```bash
# On labhost01
cd /mnt/data/homelab-base/traefik/config/

# Rename to new convention
mv dozzle.yml router-labhost00-dozzle.yml
mv prometheus.yml router-labhost00-prometheus.yml
```

Traefik will automatically detect the renamed files (file provider watch enabled).

---

**This convention applies to ALL Traefik router configuration files across the homelab infrastructure.**
