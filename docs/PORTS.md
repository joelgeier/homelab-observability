This updated ports.md follows your phased deployment strategy. It prioritizes the "Foundation" tools first and ensures the "Heavy Hitters" in Phase IV don't clash with the core infrastructure established in earlier phases.
## ports.md

| Phase [1, 2] | # | Tool | Internal | External (Remapped) | Remap Reason |
|---|---|---|---|---|---|
| I | 1 | Portainer | 9443, 8000 | 9443, 8001 | Port 8000 is reserved for Checkmk agent registration. |
| I | 2 | Uptime Kuma | 3001 | 3001 | Standard. |
| II | 3 | Prometheus | 9090 | 9090 | Standard. |
| II | 4 | Alertmanager | 9093 | 9093 | Standard. |
| II | 5 | Grafana | 3000 | 3000 | Standard. |
| III | 6 | Checkmk | 5000, 8000 | 5000, 8000 | Standard Checkmk[](https://forum.checkmk.com/t/running-checkmk-raw-in-a-docker-container-but-cant-register-new-my-host/49284) site (5000) and agent (8000) ports. |
| III | 7 | Nagios Core | 80 | 8081 | Avoids port 80 conflict with the Docker host or Checkmk frontend. |
| IV | 8 | Docker-ELK | 5601, 9200 | 5601, 9200 | Standard Kibana[](https://github.com/stefanprodan/dockprom/blob/master/README.md) (5601) and Elasticsearch (9200) ports. |
| IV | 9 | Graylog | 9000, 1514, 5044 | 9002, 1514, 5045 | Avoids Portainer GUI conflict (9000) and Wazuh Beats conflict. |
| IV | 10 | Wazuh | 443, 1514, 55000 | 8443, 1515, 55000 | Avoids standard HTTPS (443) and Graylog syslog conflict (1514). |

## Implementation Tips for the GitHub Repo:

* Networking: Use a single bridge network in your docker-compose.yml so Phase II (Prometheus/Grafana) can resolve Phase IV tools by their container names (e.g., http://graylog:9002).
* Variable Use: In your README.md, mention that these external ports should be set as variables in a .env file for easy overrides.
* Wazuh Specifics: Since Wazuh often requires multiple containers (Indexer, Manager, Dashboard), ensure the Dashboard port is the one remapped to 8443.

Would you like a starter template for the Phase I and II docker-compose.yml to get the foundation running on your Debian VM?

data = [
    {"phase": "I", "id": "1", "tool": "Portainer", "internal": "9443, 8000", "external": "9443, 8001", "remap_reason": "Avoid Checkmk agent registration conflict on 8000."},
    {"phase": "I", "id": "2", "tool": "Uptime Kuma", "internal": "3001", "external": "3001", "remap_reason": "Standard."},
    {"phase": "II", "id": "3", "tool": "Prometheus", "internal": "9090", "external": "9090", "remap_reason": "Standard."},
    {"phase": "II", "id": "4", "tool": "Alertmanager", "internal": "9093", "external": "9093", "remap_reason": "Standard."},
    {"phase": "II", "id": "5", "tool": "Grafana", "internal": "3000", "external": "3000", "remap_reason": "Standard."},
    {"phase": "III", "id": "6", "tool": "Checkmk", "internal": "5000, 8000", "external": "5000, 8000", "remap_reason": "Standard site (5000) and agent (8000) ports."},
    {"phase": "III", "id": "7", "tool": "Nagios Core", "internal": "80", "external": "8081", "remap_reason": "Avoid conflict with host/Checkmk port 80."},
    {"phase": "IV", "id": "8", "tool": "Docker-ELK", "internal": "5601, 9200", "external": "5601, 9200", "remap_reason": "Standard Kibana (5601) and ES (9200)."},
    {"phase": "IV", "id": "9", "tool": "Graylog", "internal": "9000, 1514, 5044", "external": "9002, 1514, 5045", "remap_reason": "Avoid Portainer GUI (9000) and Wazuh conflict."},
    {"phase": "IV", "id": "10", "tool": "Wazuh", "internal": "443, 1514, 55000", "external": "8443, 1515, 55000", "remap_reason": "Avoid standard HTTPS and Graylog syslog (1514)."}
]
from tabulate import tabulateheader = ["Phase", "#", "Tool", "Internal", "External (Remapped)", "Remap Reason"]table = [[d["phase"], d["id"], d["tool"], d["internal"], d["external"], d["remap_reason"]] for d in data]
print(tabulate(table, headers=header, tablefmt="github"))


[1] [https://forum.checkmk.com](https://forum.checkmk.com/t/checkmk-as-docker-agent-updater-rule-how-to-provide-http-https-tcp-port-for-update-server/30839)
[2] [https://medium.com](https://medium.com/@laupeiip/tryhackme-wazuh-write-up-7500b220a09d)

