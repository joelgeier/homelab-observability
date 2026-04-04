# QNAP Controller: Central Management & Observability Hub

## Overview
The **Controller** (QNAP Xeon D-1250 | 128GB RAM) serves as the persistent "Brain" of the homelab. While `labhost01` and `labhost02` are volatile and frequently rebuilt, the Controller remains stable to provide management, monitoring, and data persistence.

## Core Services
- **Portainer**: Container orchestration for the entire lab.
- **Uptime Kuma**: External health pings for lab services.
- **ELK Stack (Target Project)**: Centralized logging and telemetry.

---

## Project: ELK Stack Deployment
**Goal:** Deploy a persistent Elastic Stack to ingest logs/metrics from volatile lab hosts.

### Deployment Strategy
The stack will be deployed as a **single Docker Compose project** (Portainer Stack) to ensure service inter-dependency and simplified networking.

#### 1. Architecture
- **Elasticsearch (Engine):** The database and search engine. 
    - *Resource Allocation:* 8GB-16GB RAM.
    - *Persistence:* Mapped to `/share/Container/elk/data`.
- **Kibana (UI):** The visualization layer. Accessible via QNAP IP on port 5601.
- **Logstash/Fleet (Ingestion):** The entry point for data from LabHosts.

#### 2. Connection Logic
- **LabHosts (Spokes):** Run lightweight agents (Filebeat/Metricbeat) or Elastic Agent.
- **Data Flow:** LabHost Agents -> QNAP Controller (Portainer Stack) -> Elasticsearch.
- **Benefit:** When LabHosts are wiped, historical data remains searchable on the Controller.

### Critical Configuration Notes (For Implementation)
- [ ] **System Limits:** Must set `vm.max_map_count=262144` on QNAP via SSH or privileged init-container.
- [ ] **Security:** Enable Elastic Stack Security (X-Pack) and store auto-generated passwords in GitHub Secrets or a local Password Manager.
- [ ] **Networking:** Use a dedicated Docker bridge network within the stack for internal communication.

---

## Maintenance & Backup
- **Config:** All Compose files and custom configs are mirrored to GitHub.
- **Volumes:** QNAP snapshots protect the `/share/Container/` directory.

