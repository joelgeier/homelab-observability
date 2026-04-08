# LGTM Stack - Phase II Observability Core

**Status:** Planning / Pre-deployment
**Priority:** Phase II - Deploy after Portainer and Uptime Kuma

---

## Scope Decision: What is "LGTM"?

LGTM originally stands for **Loki + Grafana + Tempo + Mimir/Metrics**, but the term is used flexibly. We need to decide our implementation scope:

### Option A: Metrics-Only Core (Recommended Starting Point)
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboarding  
- **Alertmanager** - Alert routing and notifications

**Rationale:**
- ✅ Minimal resource footprint (~2-4GB RAM total)
- ✅ Fast to deploy and verify
- ✅ We already have ELK and Graylog for logs (no need for Loki yet)
- ✅ Can add Loki/Tempo later if needed

### Option B: Full LGTM Stack
Add to Option A:
- **Loki** - Log aggregation
- **Tempo** - Distributed tracing

**Considerations:**
- ⚠️ Higher resource requirements (~6-8GB RAM total)
- ⚠️ Overlap with ELK (both do logs)
- ⚠️ More complex initial setup
- ✅ Unified Grafana interface for metrics, logs, and traces

### Current Recommendation: **Option A** (Metrics-Only)

Start with Prometheus + Grafana + Alertmanager. Add Loki/Tempo in a future iteration if we need unified log/trace visualization in Grafana.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    LGTM Stack (Phase II)                │
│                      labhost00 VM                        │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   Prometheus           Grafana          Alertmanager
   (Port 9090)        (Port 3000)        (Port 9093)
        │                   │                   │
        │                   │                   │
   [scrapes]           [queries]            [routes]
        │                   │                   │
        ↓                   ↓                   ↓
    ┌─────────┐        ┌─────────┐        ┌──────────┐
    │ Targets │        │  Data   │        │  Alerts  │
    └─────────┘        │ Sources │        │ (Slack,  │
        │              └─────────┘        │ Discord) │
        │                                 └──────────┘
        │
    ┌───┴────────────────────────────┐
    │                                │
labhost01                       labhost02
- Node Exporter                 - Node Exporter
- cAdvisor (Docker)             - cAdvisor (Docker)
- Custom exporters              - Custom exporters
```

---

## Data Flow

1. **Collection:**
   - Prometheus scrapes metrics from exporters on labhost01/labhost02
   - Scrape interval: 15s (configurable)
   - Retention: 30 days (configurable)

2. **Visualization:**
   - Grafana queries Prometheus for metrics
   - Pre-configured dashboards for common use cases
   - Custom dashboards for stream-lake and deep-thought projects

3. **Alerting:**
   - Prometheus evaluates alert rules
   - Fires alerts to Alertmanager
   - Alertmanager routes to Slack/Discord/Email

---

## Deployment Plan

### Pre-requisites
- [ ] labhost00 VM running (scripts 00-05 complete)
- [ ] Docker and Docker Compose installed
- [ ] `/mnt/data/homelab-observability/lgtm-stack/` directory created
- [ ] `.env` file configured with alert webhooks

### Directory Structure
```
/mnt/data/homelab-observability/lgtm-stack/
├── prometheus/
│   ├── data/              # Time-series database
│   ├── prometheus.yml     # Scrape configuration
│   └── rules/             # Alert rules
├── grafana/
│   ├── data/              # Dashboard storage
│   ├── dashboards/        # Pre-configured JSON dashboards
│   └── datasources/       # Prometheus datasource config
└── alertmanager/
    ├── data/              # Alert state
    └── alertmanager.yml   # Routing configuration
```

### Deployment Steps
1. Create docker-compose.yml
2. Configure Prometheus scrape targets (labhost01, labhost02)
3. Set up Grafana datasource (Prometheus)
4. Import initial dashboards (Node Exporter, Docker)
5. Configure Alertmanager routing (Slack webhook)
6. Start stack: `docker-compose up -d`
7. Verify: Access Grafana at http://labhost00:3000

---

## Configuration Questions

### Prometheus
- **Scrape interval:** 15s or 30s? (15s = higher resolution, more storage)
- **Retention:** 30 days or 90 days? (longer = more storage)
- **Storage:** Default (local) or remote write to long-term storage?

### Grafana
- **Authentication:** Local admin account or SSO (Authentik)?
- **Initial dashboards:** Import community dashboards or build custom?
- **Themes:** Dark mode (default) or light mode?

### Alertmanager
- **Notification channels:** Slack only, or Slack + Discord + Email?
- **Alert grouping:** By severity, by labhost, or by service?
- **Inhibition rules:** Should high-priority alerts silence low-priority?

---

## Research & Resources

### Official Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

### Community Dashboards
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- Node Exporter Full: Dashboard ID 1860
- Docker Container Metrics: Dashboard ID 893

### Exporters for labhost01/labhost02
- **Node Exporter** - System metrics (CPU, RAM, disk, network)
- **cAdvisor** - Docker container metrics
- **Blackbox Exporter** - Endpoint availability (HTTP/HTTPS probes)
- Custom exporters for stream-lake (Kafka, ClickHouse metrics)

---

## Integration with Other Stacks

### ELK Stack
- Grafana can query Elasticsearch for logs
- Add Elasticsearch datasource to Grafana
- Unified view: metrics (Prometheus) + logs (Elasticsearch)

### Uptime Kuma
- Prometheus can scrape Uptime Kuma's metrics endpoint
- Visualize uptime data alongside other metrics

### Wazuh
- Wazuh has Prometheus exporter for security metrics
- Correlate security events with system performance

---

## Next Steps

1. **Decide scope:** Metrics-only (A) or full LGTM (B)?
2. Create `docker-compose.yml` for chosen scope
3. Configure Prometheus scrape targets
4. Set up Grafana datasources and dashboards
5. Configure Alertmanager notification channels
6. Deploy and verify

---

## Notes & Observations

- Prometheus + Grafana + Alertmanager is the industry-standard metrics stack
- Appears in ~80% of job descriptions for DevOps/SRE roles
- Learning this stack is high-value for career progression
- LGTM is Grafana Labs' commercial offering; we're self-hosting the OSS components
