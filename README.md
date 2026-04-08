# homelab-controller: Central Management & Observability Hub

https://github.com/joelgeier/homelab-controller/ 

## Overview

The **Controller** (QNAP Xeon D-1250 | 128GB RAM) serves as the persistent "Brain" of the homelab. While `labhost01` and `labhost02` are volatile and frequently rebuilt, the Controller remains stable to provide management, monitoring, and data persistence.

**QNAP Container Station** is used to deploy the services as docker "applications" the QNAP term for what Portainer calls "stacks"

This is a new project commenced in April 2026 to consolidate experiments with individual tools and create a stable observability stack, upon which I can then ponder attempting various use cases.  These use cases are captured in the "projects" folder under each tools folder, in my GitHub project 


## Core Services

Based upon professional experiance, job descriptions, expanding my support capabilites and intended learning pathways for linux admin and devops.  Since my professional domain is trading platforms, the tools list reflects what is likely to be relevant those firms, and the use cases relevant to support activies, within brokers, banks, hedge funds or software vendors that sell solutions to these firms.

The "caveat" in this thinking, every tool needs to offer a free community edition which can be deployed via docker.  I have used Splunk in the past, there is a free version this could be added to the mix, zabbix, a do everything tool, maybe? Datadog offer free accounts, but dont have self hosted, alternatives like SigNoz or Netdata could be dropped in the observability stack, but that is generating to much overlap.  The intention is to choose one tool in each category that has a different primary focus, and create a few projects on each, that are not the scope of the other tools.

## The Monitoring Stack

| #  | Tool | Category | Primary Focus | Best Use Case |
|:-- |:--- | :--- | :--- | :--- |
| 1  | **Portainer** | **Orchestration** | Container Management | GUI for native QNAP docker lifecycle. |
| 2  | **Uptime Kuma** | **Availability** | Web/Service Uptime | Simple "Up/Down" dashboard with alerts. |
| 3  | **Prometheus** | **Performance** | Time-Series Metrics | Scraped application performance (JVM, DBs). |
| 4  | **Alertmanager** | **Notification** | Event Alerting | Notify DevOps via messaging App, of system failure |
| 5  | **Grafana** | **Visualization** | Unified Dashboarding | One "Single Pane of Glass" for all data. |
| 6  | **checkmk** | **Infrastructure** | Physical Hardware State | SNMP for QNAP RAID, Meraki, & HP iLO. |
| 7  | **Nagios Core** | **Infrastructure** | Physical Hardware State | SNMP for QNAP RAID, Meraki, & HP iLO. |
| 8  | **Docker-ELK** | **Logging** | Search & Troubleshooting | Heavy log analysis for Kafka/Clickhouse. |
| 9  | **Graylog** | **Security/SIEM** | Log Correlation | Auth auditing (Authentik) & Syslog. |
| 10  | **wazuh** | **Security/SIEM** | Log Correlation | Auth auditing (Authentik) & Syslog. |


add wazuh, bash script for wazuh agents, add wazah agent to infra scrip

#### scratchpad for dashboard - delete 

panel 1 - Orchestration 
panel 2 - Infrastuture 
Panel 3 - Application ELK Stack 
Panel 4 - XDR & SIEM
Panel 5 - Notications

## Why So Many Tools? (Key Differentiators)

- **Nagios vs. Prometheus:** Nagios tracks the *bones* (Is the fan spinning? Is the disk healthy?). Prometheus tracks the *pulse* (How many queries per second?).
- **ELK vs. Graylog:** ELK is a powerful "search engine" for raw logs. Graylog is a "security engine" designed to parse, stream, and alert on structured logs (like Authentik's auth events).
- **Uptime Kuma vs. Nagios:** Kuma is for a quick "Is my website up?" check. Nagios is for deep-dive enterprise infrastructure monitoring.

Portainer is presently deployed as a native QNAP app, not going move that at this time.  Prometheus and Grafana are living inside the labhost01 - streamlake project, not good architecture but it can stay there for the momment.  Uptime-Kuma is muppet level simple, this project cycle is focused on standing up docker-elk, nagios and graylog in container station, and implementing one use case in each.

## Homelab Project Stacks 

My homelab projects have been consolidated into 3 primary projects, each are documented in github

- labhost01: **stream-lake** - a streaming data, storage and analytics stack - this generates enough telemetary data to experiment with different observability tools
- labhost02: **deep-thought** - an AI and agent development stack, this is being rebuilt, and I have not considered what telemetary data this might offer
- labhost03: **automation-lab** - not built yet, this will have gitea, ansible, terrorform and other tools to support my devops journey, again no thoughts yet, on telematory or observability


## Project Boundaries
- **In-Scope:** Monitoring logic, container orchestration, hardware telemetry.
- **Out-of-Scope:** Private NAS functions, personal storage, or shared house network configs I'm not allowed to touch.



## Technical Topology & "Old Junk" Hardware

The **Meraki MS220-8P** is the backbone. Even if my lab hosts (ProDesk/Microserver) are down, the QNAP stays on.

[ RESIDENTIAL ROUTER ] (Gateway)

          |
[ MERAKI MS220-8P ] (The Switch Fabric)
    |
    |---------- [ QNAP TVS-h1288x ] (The Monitoring Hub)

    |             |-- Container Station: [ PORTAINER ] [ NAGIOS ] [ ELK ] ...
    |

    |---------- [ HP PRODESK G3 ] (labhost01: Data Projects)
    |             |-- Proxmox / RHEL Admin / Debian 13
    |

    |---------- [ HP MICROSERVER G8 ] (labhost02: AI/Agents)
                  |-- Port 1: iLO 4 (Management - Unlicensed)
                  |-- Port 2: ESXi (Hypervisor)


## Research Archive & Inspiration
- [Network Monitoring 101 - YouTube Link]
- [Enterprise vs. Homelab Observability - Article Link]



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


## The "Day 0" Deployment Roadmap

| Phase | # | Tool | Logic for Order |
|---|---|---|---|
| I: The Foundation | 1 | Portainer | Your "Command Center." Deploy this first so you can monitor logs and container health for the other 9. |
| | 2 | Uptime Kuma | The "Pulse Check." Immediately add the other 9 tool URLs as you deploy them to see them go "Green." |
| II: The Metrics Hub | 3 | Prometheus | The data collector. It needs to be up before Alertmanager or Grafana can do anything useful. |
| | 4 | Alertmanager | Pairs with Prometheus. Get your notification logic (Discord/Slack/Email) tested early. |
| | 5 | Grafana | The "Single Pane of Glass." Connect it to Prometheus immediately to see your first live graphs. |
| III: Infrastructure | 6 | Checkmk | The heavy lifter for SNMP/Hypervisors. It's more modern and easier to "Dockerize" than Nagios. |
| | 7 | Nagios Core | Deploy this next to handle legacy SNMP or specific custom scripts that Checkmk might not cover. |
| IV: The Heavy Hitters | 8 | Docker-ELK | Warning: High RAM usage. Requires vm.max_map_count host tweaks. Get the log engine running first. |
| | 9 | Graylog | Sits "on top" of MongoDB/OpenSearch. Use this for user-friendly log searching and dashboarding. |
| | 10 | Wazuh | The most complex. It has its own Indexer, Dashboard, and Manager. Best saved for last once the VM is stable. |

## Strategic Benefits of this Order:

   1. Phase I (1-2): Confirms your Docker networking and external IP access work perfectly with minimal resource load.
   2. Phase II (3-5): Builds your "Observability Core." You can now monitor the CPU/RAM usage of the heavier tools in Phase IV using Prometheus/Grafana.
   3. Phase III (6-7): Connects your "Boxes" (VMware/Proxmox). Since these use APIs/SNMP, they don't require agent installs yet.
   4. Phase IV (8-10): These tools are the most likely to crash a VM if resources aren't managed. By doing them last, you have 7 other tools already working to help you troubleshoot why they failed.

Pro-Tip for the VM: Since you are using Debian 13, I highly recommend creating a Docker Network called monitoring_nw in your Compose file so Phase II tools can "see" Phase IV tools by name.
Does this phased roadmap look like a solid plan for your GitHub repo's README.md?


------------------------------

## 🛠️ Unified Agent Strategy

To ensure deep observability across all 10 tools on labhost00, every client host (labhost01, labhost02, etc.) runs a consolidated agent stack. This stack is deployed via a single automated script.

## Agent Registry & Responsibilities

| Agent | Source Tool | Role & Responsibility | Replaces / Consolidates |
|---|---|---|---|
| Elastic Agent | ELK / Graylog | Unified Data Shipper: System metrics, container logs, and network traffic. Managed via Fleet. | Filebeat, Metricbeat, Packetbeat |
| Wazuh Agent | Wazuh | Security & SIEM: File Integrity Monitoring (FIM) and vulnerability detection. | OSSEC, Rootcheck |
| Checkmk Agent | Checkmk | Infrastructure Health: Deep hardware monitoring, SMART status, and OS service health. | SNMP (for Linux hosts) |
| NCPA Agent | Nagios Core | Custom Checks: Executes local bash/python scripts for unique lab conditions. | NRPE, check_by_ssh |
| Portainer Agent | Portainer | Orchestration: Enables remote Docker management and container console access. | Direct Docker API exposure |
| Node Exporter | Prometheus | Performance Metrics: High-resolution time-series metrics for Grafana dashboards. | N/A |

## Estimated Resource Impact (Per Client)

| Agent | Average RAM Usage | Impact Level |
|---|---|---|
| Elastic Agent | 200–400 MB | Moderate |
| Wazuh Agent | 60–120 MB | Low |
| NCPA Agent | 25–45 MB | Very Low |
| Node Exporter | 15–30 MB | Very Low |
| Portainer Agent | 15–30 MB | Very Low |
| Checkmk Agent | 5–15 MB | Negligible |
| TOTAL AGGREGATE | ~320–640 MB | Lightweight |

## Deployment Logic

All agents are deployed using the scripts/02-client-full-deploy.sh script. This handles binary installation, systemd service enablement, and automatic enrollment to the labhost00 hub.

## Maintenance & Backup

- **Config:** All Compose files and custom configs are mirrored to GitHub.
- **Volumes:** QNAP snapshots protect the `/share/Container/` directory.





