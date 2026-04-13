# Nagios – Infrastructure Monitoring Use Cases (Homelab Observability)

**Project:** homelab-observability
**Component:** Nagios (Infrastructure / State Monitoring)
**Author:** Joel Geier
**Version:** v0.2 (Consolidated Research & Strategy)

---

# 1. Introduction

## What is Nagios?

Nagios Core is an open-source infrastructure monitoring system that operates as a **state-based monitoring engine**. It executes scheduled checks via plugins and determines whether systems and services are in an **OK, WARNING, or CRITICAL** state.

Unlike modern metric-based systems, Nagios focuses on **availability and correctness**, not trends.

## Role in an Enterprise Stack

In a typical enterprise observability architecture:

* Nagios answers: *“Is this system working?”*
* It complements:

  * Metric systems (e.g. Prometheus)
  * Log systems (e.g. ELK)

Nagios is particularly strong for:

* Hardware health monitoring
* Network state validation
* Alerting on discrete failures

## Why Include Nagios in This Project?

This homelab aims to demonstrate competency across multiple observability domains. Nagios is included to represent:

* **Traditional infrastructure monitoring**
* **Plugin-based extensibility**
* **State-driven alerting models still widely used in enterprise environments**

---

# 2. Intended Use Cases

To avoid overlap with other tools in the stack, Nagios will focus on **infrastructure-level visibility**, not application metrics or logs.

## Use Case A: Hardware Health Monitoring (HP iLO)

**Goal:**
Monitor physical server health without requiring a licensed management interface.

**Method:**

* Query iLO via:

  * SNMP
  * or XML/Redfish endpoints
* Use Nagios plugins (e.g. `check_ilo2_health`)

**Value Demonstrated:**

* Monitoring legacy/unlicensed enterprise hardware
* Detecting failures at the **physical layer**

---

## Use Case B: Network Fabric Integrity (Cisco Meraki)

**Goal:**
Validate connectivity between infrastructure components.

**Method:**

* Use Meraki Dashboard API and/or SNMP
* Monitor:

  * Port status
  * Link state
  * Connectivity dependencies

**Value Demonstrated:**

* Monitoring the **network as a dependency layer**
* Understanding that application health depends on network path integrity

---

## Use Case C: Storage & RAID Health (QNAP)

**Goal:**
Detect disk or RAID degradation before service impact.

**Method:**

* SNMP polling of QNAP
* Example OID class:

  * RAID status / disk health metrics

**Value Demonstrated:**

* Hardware-level data integrity awareness
* Separation of:

  * Storage health vs application/database health

---

# 3. Lab Topology Overview

Nagios will operate within the broader homelab observability environment.

## Logical Design

```
[ Shared Router ]
        |
[ Meraki MS220-8P Switch ]
        |
        |--- [ QNAP TVS-h1288x ] (Monitoring Hub)
        |        ├── Nagios
        |        ├── ELK Stack
        |        └── Prometheus Stack
        |
        |--- [ HP ProDesk G3 ]
        |        └── Proxmox / RHEL
        |
        |--- [ HP Microserver G8 ]
                 ├── iLO 4 (Mgmt)
                 └── ESXi (Hypervisor)
```

## Design Principles

* QNAP acts as **central monitoring hub**
* Nagios monitors:

  * Hardware
  * Network fabric
  * Storage layer
* Other tools handle:

  * Metrics (Prometheus)
  * Logs (ELK)

---

# 4. Nagios in Docker – Ecosystem Evaluation

## Key Discovery

Nagios Docker images are:

* Community-maintained
* Inconsistent in update cadence
* Vary significantly in included components

**Important Insight:**
Popularity of an image does not guarantee it is actively maintained.

---

## Candidate Images

### 1. tronyx/nagios

* Base: Ubuntu 24.04
* Core: ~4.5.9+
* Includes:

  * NagiosTV
  * Nagiosgraph
  * NRPE, NCPA, NSCA

### 2. manios/nagios

* Base: Alpine Linux
* Core: ~4.5.12+
* Focus:

  * Lightweight
  * Minimal footprint

### 3. instantlinux/nagios

* Base: Alpine
* Core: ~4.5.8+
* Focus:

  * Modular
  * Often paired with NagiosQL

### 4. jasonrivers/nagios

* Legacy image
* Historically popular
* Mixed maintenance history

---

## Comparison Table

| Feature              | tronyx       | manios                   | instantlinux |
| -------------------- | ------------ | ------------------------ | ------------ |
| Base OS              | Ubuntu       | Alpine                   | Alpine       |
| Footprint            | Medium       | Very Low                 | Low          |
| Core Version         | 4.5.9+       | 4.5.12+                  | 4.5.8+       |
| Plugin Support       | High         | Moderate                 | Moderate     |
| Ease of Extension    | High (apt)   | Lower (musl limitations) | Moderate     |
| Visual Add-ons       | Yes          | No                       | No           |
| Architecture Support | amd64, arm64 | broad ARM                | amd64        |

---

# 5. Resource Considerations

## tronyx/nagios

* Idle: ~256–512MB RAM
* Best for:

  * Compatibility
  * Feature-rich deployments

## manios/nagios

* Idle: ~50–100MB RAM
* Best for:

  * Minimal environments
  * Resource-constrained systems

## Scaling Factors

Resource usage increases with:

* Number of hosts/services
* Check frequency
* Plugin complexity (SNMP, scripts, APIs)
* Graphing features enabled

---

# 6. Impact of Use Cases on Image Selection

## Hardware Monitoring (HP iLO)

* Requires:

  * SNMP tools
  * Potential Redfish libraries

→ Favors **Ubuntu-based images** (easier dependency management)

---

## Meraki API Integration

* Requires:

  * Python or PHP runtime
  * API clients

→ Favors images with broader runtime support

---

## SNMP (QNAP RAID)

* Supported by all images
* Simpler requirement

→ No strong constraint

---

## Summary

| Requirement            | Preferred Image Characteristic |
| ---------------------- | ------------------------------ |
| Hardware plugins       | Ubuntu-based                   |
| API integrations       | Pre-installed runtimes         |
| Lightweight deployment | Alpine-based                   |
| Demo/visual appeal     | Pre-bundled dashboards         |

---

# 7. Decision Framework

At this stage, no final image has been selected.

The choice will be guided by:

## If prioritizing:

* Ease of setup
* Plugin compatibility
* Demo readiness

→ Favor **feature-rich images**

## If prioritizing:

* Efficiency
* Minimal footprint
* Clean modular design

→ Favor **lightweight Alpine images**

---

# 8. Key Observations

* Nagios excels as a **state engine**, not a visualization platform
* Modern observability stacks often:

  * Separate alerting, metrics, and visualization
* Docker introduces trade-offs:

  * Convenience vs flexibility
* Ubuntu vs Alpine is a **critical decision point**

---

# 9. Implementation Strategy (Next Phase)

## Phase 1 – Validation

* [ ] Deploy candidate container
* [ ] Validate SNMP connectivity
* [ ] Test basic checks

## Phase 2 – Use Case Implementation

* [ ] HP iLO health checks
* [ ] Meraki API monitoring
* [ ] QNAP RAID SNMP checks

## Phase 3 – Refinement

* [ ] Tune alert thresholds
* [ ] Reduce alert noise (soft vs hard states)
* [ ] Align with other observability tools

---

# 10. Future Structure

Planned repository layout:

```
nagios/
├── README.md (this document)
├── docker/
│   └── (compose + env files – future)
├── use-cases/
│   ├── ilo-health/
│   ├── meraki-network/
│   └── qnap-raid/
```

---

# 11. Next Steps

* Consolidate research into final image selection
* Begin controlled deployment
* Implement first use case (HP iLO)




