Since labhost00 is your "Management Node" and sits behind Tailscale, your networking.md needs to map out how data flows from your physical boxes (VMware/Proxmox) and your containers into this central hub.
Here is a template you can drop into your /docs folder:
## networking.md## 1. Host Identity

* Hostname: labhost00
* OS: Debian 13 (Trixie)
* Physical Interface (QNAP Bridge): eth0 / enp0s3
* Tailscale Interface: tailscale0
* Tailscale DNS: labhost00.[your-tailnet-name].ts.net

## 2. Network Segmentation

| Layer | Range (Example) | Purpose |
|---|---|---|
| Physical LAN | 192.168.x.x | Access to QNAP, ESXi, and Proxmox management. |
| Tailscale (VPN) | 100.x.x.x | Remote access to dashboards and cross-site monitoring. |
| Docker Bridge | 172.20.0.0/16 | Internal container-to-container communication. |

## 3. Traffic Flow (The "Observability" Paths)
To ensure the 10 tools actually get data, the following paths must be open:

* Inbound (Metrics/Logs):
* SNMP (UDP 161/162): From ESXi/Proxmox → labhost00 (Checkmk/Nagios).
   * Syslog (UDP 1514/1515): From VMs/Network Gear → labhost00 (Graylog/Wazuh).
   * Prometheus Scrapes (TCP 9000-9500): From Lab Apps → labhost00 (Prometheus).
* Outbound (Alerts):
* HTTPS (TCP 443): From labhost00 → Internet (Discord/Slack/Pushover via Alertmanager).

## 4. Tailscale Integration Strategy

* Subnet Routing: (Optional) If labhost00 is configured as a Tailscale Subnet Router, you can monitor your Proxmox/VMware hosts even if they don't have Tailscale installed.
* Local Nameserver: Set labhost00 as a global nameserver in the Tailscale admin console to use MagicDNS for all monitoring links.

## 5. Docker DNS & Service Discovery
All 10 tools are joined to the monitoring_nw Docker network.

* Internal Discovery: Tools should talk to each other using container names (e.g., Grafana connects to Prometheus at http://prometheus:9090, not an IP).
* External Access: Users connect via the Tailscale IP and the Remapped Port defined in ports.md.

------------------------------
Next Step: Since you're using Debian 13, would you like the specific CLI commands to set up the persistent folder structure on labhost00 so your Docker volumes don't get messy?

