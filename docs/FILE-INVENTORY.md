# homelab-observability - GitHub Repository File Inventory

**Generated:** 2026-04-09  
**Purpose:** Pre-deployment verification checklist

---

## 📋 Repository Structure & Version Control

### Root Level Files

| File | Version | Status | Description |
|------|---------|--------|-------------|
| `.gitignore` | - | ✅ Ready | Git exclusion rules |
| `.env.example` | - | ✅ Ready | Environment variable template |
| `README.md` | - | ✅ Ready | Project overview & topology |

### Documentation (`/docs/`)

| File | Version | Status | Description |
|------|---------|--------|-------------|
| `INSTALL.md` | 1.0.0 | ✅ Ready | Debian 13.4 VM installation record |
| `PORTS.md` | 1.0.0 | ✅ Ready | Port assignments (Phase 0-IV) |
| `DOCKER-COMPOSE-CHECKLIST.md` | 1.0.0 | ✅ Ready | Compose file refactoring checklist |
| `TRAEFIK-CONFIGURATION.md` | 1.0.0 | ✅ Ready | Complete Traefik router creation & deployment guide |
| `TAILSCALE-NETWORK.md` | 1.0.0 | ✅ Ready | Tailscale VPN network configuration & URL standards |
| `CONSOLES.md` | - | ⚠️ Check | Console access documentation |
| `networking.md` | - | ⚠️ Check | Network configuration notes |

### Traefik Router Configs (`/traefik-routers/`)

**Purpose:** Version-controlled storage for all Traefik router configurations. Deploy by copying to active Traefik instance.

| File | Version | Status | Description |
|------|---------|--------|-------------|
| `router-labhost00-dozzle.yml` | 1.0.0 | ✅ Ready | Dozzle cross-host routing (labhost01 → labhost00) |

**Deployment:** Copy to wherever Traefik is running (e.g., `/mnt/data/homelab-base/traefik/config/` on labhost01)

### Bootstrap Scripts (`/scripts/`)

| File | Version | Status | Description |
|------|---------|--------|-------------|
| `00-root-bootstrap.sh` | 1.0.0 | ✅ Tested | Root setup (sudo, labadmin) |
| `01-preflight.sh` | 1.1.0 | ✅ Tested | Environment validation (fixed for Debian 13) |
| `02-packages.sh` | 1.0.0 | ✅ Tested | CLI tools installation (44 packages) |
| `03-docker.sh` | 1.0.0 | ✅ Tested | Docker CE + Compose + Portainer Agent |
| `04-tailscale.sh` | 1.0.0 | ✅ Tested | Tailscale VPN mesh |
| `05-init-directories.sh` | 1.0.0 | ✅ Tested | Data directory creation |
| `README.md` | - | ✅ Ready | Scripts execution guide |
| `labhost00-deploy.sh` | - | ⚠️ Check | Deployment wrapper script |

---

## 🐋 Tool Deployments

### Phase 0: Foundation

#### 02-dozzle (Real-time Container Logs)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `docker-compose.yml` | 1.0.0 | ✅ Ready | Dozzle v8.10.2 deployment |
| `README.md` | 1.0.0 | ✅ Ready | Deployment & configuration guide |

**Traefik Router:** See `/traefik-routers/router-labhost00-dozzle.yml`  
**Deployment Status:** Ready for deployment  
**Port:** 8888 (avoiding 8080 conflicts)  
**Dependencies:** Docker daemon

---

### Phase I: Core Monitoring

#### 01-portainer (Container Management)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | - | ⚠️ Placeholder | Needs compose file |

**Status:** ⚠️ Portainer Agent deployed via script 03, full Portainer needs compose

---

#### 02-dozzle (Duplicate?)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | - | ⚠️ Check | Possible duplicate of 01-dozzle? |

**Status:** ⚠️ Investigate - may be duplicate directory

---

#### 03-uptime-kuma (Uptime Monitoring)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | - | ⚠️ Placeholder | Needs compose file |

**Status:** ⚠️ Not ready - needs docker-compose.yml

---

### Phase II: LGTM Stack (Metrics)

#### 04-lgtm-stack (Prometheus + Grafana + Alertmanager)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | 1.0.0 | ✅ Ready | Planning document (scope, architecture, deployment) |

**Status:** ⚠️ Planning complete - needs docker-compose.yml files

---

### Phase IV: Heavy Hitters

#### 05-docker-elk (Elasticsearch, Logstash, Kibana)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `docker-compose.yml` | - | ⚠️ Check | Needs version verification |
| `README.md` | - | ⚠️ Check | Needs review |
| `projects/README.md` | - | ⚠️ Check | Projects documentation |

**Status:** ⚠️ Exists but needs version audit

---

#### 07-graylog (Log Management)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `docker-compose.yml` | - | ⚠️ Check | Needs version verification |
| `.env.example` | - | ⚠️ Check | Environment variables |
| `README.md` | - | ⚠️ Check | Needs review |
| `projects/README.md` | - | ⚠️ Check | Projects documentation |

**Status:** ⚠️ Exists but needs version audit

---

#### 06-nagios (Infrastructure Monitoring)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | - | ⚠️ Placeholder | Needs compose file |

**Status:** ⚠️ Not ready

---

#### 08-wazuh (Security Monitoring - SIEM/XDR)
| File | Version | Status | Description |
|------|---------|--------|-------------|
| `README.md` | 1.0.0 | ✅ Ready | Comprehensive Wazuh deployment guide |

**Deployment Method:** Official wazuh-docker repository (single-node)  
**Access:** `https://labhost00.taild6529.ts.net:8443`  
**Components:** Manager (1515), Indexer (9200), Dashboard (8443)  
**Agent Deployment:** Instructions for labhost01 included  
**Dependencies:** Docker, vm.max_map_count=262144  
**Sources:** Official Wazuh docs + homelab implementations (0x2A Security Blog)  
**Use Cases:** Vulnerability scanning, FIM, log analysis, brute-force detection, Docker monitoring  
**Status:** ✅ Ready for deployment

---

## 📊 Other Documentation

| File | Location | Version | Status | Description |
|------|----------|---------|--------|-------------|
| `BUILD-READY.md` | Root | - | ⚠️ Check | Build status tracking |
| `HOUSEKEEPING.md` | Root | - | ⚠️ Check | Maintenance notes |
| `STATUS.md` | Root | - | ⚠️ Check | Project status |
| `prompt_style_guide.md` | Root | - | ⚠️ Check | Style guide for AI prompts |

---

## ✅ Pre-Deployment Checklist

### Critical Files (Must Have)
- [x] `.gitignore`
- [x] `.env.example`
- [x] `README.md` (root)
- [x] `docs/INSTALL.md`
- [x] `docs/PORTS.md`
- [x] `docs/DOCKER-COMPOSE-CHECKLIST.md`
- [x] All bootstrap scripts (00-05)
- [x] `01-dozzle/` (complete with compose + docs)

### Files to Review
- [ ] Check for duplicate `02-dozzle/` directory
- [ ] Verify `05-docker-elk/` compose file version
- [ ] Verify `07-graylog/` compose file version
- [ ] Review `labhost00-deploy.sh` purpose
- [ ] Check all placeholder READMEs

### Missing (To Create Later)
- [ ] `03-uptime-kuma/docker-compose.yml`
- [ ] `04-lgtm-stack/docker-compose.yml` (or subdirectories for each service)
- [ ] Portainer full deployment (if needed beyond agent)
- [ ] Nagios, Wazuh compose files

---

## 🚀 Deployment Priority

**Ready to Deploy Now:**
1. ✅ Dozzle (`01-dozzle/`) - Complete, versioned, documented

**Next to Complete:**
2. ⚠️ Uptime Kuma - Needs compose file
3. ⚠️ LGTM Stack - Planning done, needs compose implementation

**Later Phases:**
4. ⚠️ ELK, Graylog - Have compose files but need version audit
5. ⚠️ Nagios, Wazuh - Need everything

---

## 📝 Notes

- Bootstrap scripts all tested on labhost00 ✅
- Dozzle is only fully production-ready tool ✅
- Several placeholder directories exist from earlier planning
- Need to audit existing compose files (ELK, Graylog) for version numbers
- Cross-host Traefik routing documented in Dozzle example

