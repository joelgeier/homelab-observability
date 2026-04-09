# Wazuh - Open Source SIEM & XDR Platform

**Purpose:** Enterprise-grade security monitoring for the homelab - detect vulnerabilities, monitor file integrity, analyze logs, and respond to threats on labhost01.

**Version:** 4.x (latest stable)  
**Last Updated:** 2026-04-09  
**Phase:** IV (Heavy Hitters - Security & Advanced Monitoring)

---

## 🎯 What is Wazuh?

**Wazuh is a free, open-source Security Information and Event Management (SIEM) platform** that provides:

- **XDR (Extended Detection & Response)** - Unified security across endpoints, cloud, and containers
- **Threat Detection** - Real-time analysis of security events and anomalies
- **Vulnerability Scanning** - Maps installed packages against CVE databases
- **File Integrity Monitoring (FIM)** - Detects unauthorized file changes
- **Log Analysis** - Centralizes and analyzes logs from all monitored hosts
- **Incident Response** - Automated threat mitigation via active response
- **Compliance Monitoring** - CIS benchmarks, PCI DSS, GDPR, HIPAA
- **Container Security** - Monitors Docker events and container activity

**Think of it as:** Your homelab's security operations center (SOC) in a box.

---

## 🏗️ Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                     labhost00 (Wazuh Server)                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐│
│  │  Wazuh Manager   │  │  Wazuh Indexer   │  │  Dashboard ││
│  │                  │  │                  │  │            ││
│  │ - Event analysis │  │ - Data storage   │  │ - Web UI   ││
│  │ - Detection rules│  │ - OpenSearch     │  │ - Port 8443││
│  │ - Agent mgmt     │  │ - Indexing       │  │            ││
│  │ - Port 1515      │  │ - Port 9200      │  │            ││
│  └──────────────────┘  └──────────────────┘  └────────────┘│
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ Forwards logs & events
                            │
┌─────────────────────────────────────────────────────────────┐
│                   labhost01 (Monitored Host)                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Wazuh Agent                              │  │
│  │                                                       │  │
│  │ - Collects system logs                               │  │
│  │ - Monitors file changes                              │  │
│  │ - Detects vulnerabilities                            │  │
│  │ - Reports to Manager (192.168.1.100:1515)            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
labhost01 Agent
    ↓ (collects)
System logs, auth events, file changes, process creation
    ↓ (forwards)
Wazuh Manager (analyzes, applies rules, triggers alerts)
    ↓ (indexes)
Wazuh Indexer (stores for search/analysis)
    ↓ (displays)
Wazuh Dashboard (visualize, investigate, respond)
```

---

## 📋 Requirements

### Hardware (labhost00 - Wazuh Server)

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **RAM** | 4GB | 8GB | Indexer is memory-intensive |
| **Disk** | 20GB | 50GB+ | 90 days of logs per 100 agents |
| **CPU** | 2 cores | 4 cores | For log processing |

**Current labhost00 specs:** 4 cores, 8GB RAM, 64GB disk - **Perfect for Wazuh!**

### System Configuration

**CRITICAL: Configure vm.max_map_count before deployment**

Wazuh Indexer (based on OpenSearch/Elasticsearch) creates many virtual memory areas. Linux kernel must allow more than the default 65530.

```bash
# On labhost00 (Docker host)
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Verify:**
```bash
sysctl vm.max_map_count
# Should output: vm.max_map_count = 262144
```

### Port Assignments

From `PORTS.md`:

| Port | Purpose | Remapped | Access |
|------|---------|----------|--------|
| 443 → **8443** | Dashboard (HTTPS Web UI) | Avoid HTTPS conflict | `https://labhost00.taild6529.ts.net:8443` |
| 1514 → **1515** | Agent communication (syslog) | Avoid Graylog conflict | Internal only |
| 55000 | API & Agent registration | No change | Internal only |

---

## 🚀 Installation - Docker Single-Node Deployment

### Why Docker for Wazuh?

**Advantages for Homelabs:**
- ✅ **Fast deployment** - Full stack in 10-15 minutes
- ✅ **Isolated environment** - No conflicts with host system
- ✅ **Easy updates** - Pull new images, recreate containers
- ✅ **Data persistence** - Volumes survive container recreation
- ✅ **Single-host suitable** - Monitors up to 100 endpoints

**Single-node vs Multi-node:**
- **Single-node:** All components on labhost00 - perfect for homelab (<100 agents)
- **Multi-node:** Distributed cluster - overkill for our use case

### Deployment Method: Official Wazuh Docker Repository

We'll use Wazuh's official Docker deployment repository rather than creating a custom docker-compose.yml from scratch. This ensures:
- ✅ Tested, production-ready configuration
- ✅ Proper inter-component communication
- ✅ Secure certificate generation
- ✅ Regular updates from Wazuh team

### Step 1: Clone Official Repository

```bash
# On labhost00
cd ~
git clone https://github.com/wazuh/wazuh-docker.git -b v4.x
cd wazuh-docker/single-node
```

**Why `-b v4.x`?**
- Tracks the latest stable 4.x release
- Auto-updates when pulling new changes

### Step 2: Generate SSL Certificates

Wazuh components communicate securely via TLS. Generate self-signed certificates:

```bash
docker-compose -f generate-indexer-certs.yml run --rm generator
```

**What this does:**
- Creates root CA certificate
- Generates certificates for Manager, Indexer, Dashboard
- Stores in `config/wazuh_indexer_ssl_certs/` directory

### Step 3: Deploy Wazuh Stack

```bash
docker-compose up -d
```

**Containers started:**
1. **wazuh.manager** - Security event processing engine
2. **wazuh.indexer** - Data storage (OpenSearch fork)
3. **wazuh.dashboard** - Web UI (Kibana fork)

**Expected startup time:** 1-2 minutes (Indexer takes longest)

### Step 4: Verify Deployment

```bash
# Check all containers are running
docker-compose ps

# Expected output:
# NAME              STATUS        PORTS
# wazuh.manager     Up 2 minutes  1514-1515/tcp, 55000/tcp
# wazuh.indexer     Up 2 minutes  9200/tcp
# wazuh.dashboard   Up 2 minutes  0.0.0.0:443->5601/tcp
```

**Monitor startup logs:**
```bash
docker-compose logs -f wazuh.dashboard
```

**Look for:** 
```
Server running at https://0.0.0.0:5601
```

**Common startup messages (ignore these):**
- `Failed to connect to Wazuh indexer port 9200` - Normal during first minute
- `Wazuh dashboard server is not ready yet` - Wait ~60 seconds for Indexer

### Step 5: Access Dashboard

**URL:** `https://labhost00.taild6529.ts.net:8443`

**Default Credentials:**
- **Username:** `admin`
- **Password:** `SecretPassword`

**⚠️ CRITICAL: Change default password immediately after first login!**

---

## 🔐 Post-Installation Security

### Change Default Passwords

**Option 1: Wazuh Passwords Tool (Recommended)**
```bash
# On labhost00
docker exec -it wazuh.indexer bash

# Inside container
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh \
  --api --change-all --admin-user wazuh --admin-password wazuh
```

**Option 2: Manual Password Change**

Generate password hash:
```bash
docker run --rm -ti wazuh/wazuh-indexer:4.11.2 \
  bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
```

Edit `config/wazuh_indexer/internal_users.yml` and replace hash for admin user.

Apply changes:
```bash
docker restart wazuh.indexer wazuh.dashboard
```

### Certificate Warnings

**Browser shows "Your connection is not private"**
- Self-signed certificates trigger this warning
- **For homelab:** Click "Advanced" → "Proceed" (acceptable risk on Tailscale network)
- **For production:** Generate proper certificates from Let's Encrypt or trusted CA

---

## 📦 Installing Wazuh Agent (labhost01)

### Why Install Agent on labhost01?

The Wazuh Manager (server) is passive - it cannot scan remote hosts. **Agents are required** to:
- Collect system logs
- Monitor file changes
- Detect vulnerabilities in installed packages
- Report SSH attempts, authentication failures
- Monitor Docker container activity

### Agent Installation - Debian/Ubuntu

**On labhost01 (monitored host):**

```bash
# Add Wazuh repository GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --dearmor -o /usr/share/keyrings/wazuh.gpg

# Add Wazuh repository
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list

# Update package list
sudo apt-get update

# Install agent (set manager IP during install)
WAZUH_MANAGER="192.168.1.100" sudo apt-get install wazuh-agent -y

# Enable and start agent
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

**What `WAZUH_MANAGER="192.168.1.100"` does:**
- Automatically configures agent to connect to labhost00 (where Manager runs)
- No manual config file editing required

### Verify Agent Connection

**On labhost01:**
```bash
sudo systemctl status wazuh-agent
# Should show: Active (running)
```

**Check logs:**
```bash
sudo tail -f /var/ossec/logs/ossec.log
```

**Look for:**
```
INFO: Connected to the server (192.168.1.100:1515)
```

**On labhost00 Dashboard:**
1. Navigate to **Agents** in web UI
2. Should see `labhost01` listed with status "Active"
3. Green indicator = agent connected successfully

### Agent Not Showing Up?

**Troubleshooting:**
```bash
# On labhost01 - check agent config
sudo cat /var/ossec/etc/ossec.conf | grep -A 5 "<server>"

# Should show:
# <server>
#   <address>192.168.1.100</address>
#   <port>1515</port>

# Test connectivity
telnet 192.168.1.100 1515
# Should connect (Ctrl+C to exit)

# Restart agent
sudo systemctl restart wazuh-agent
```

---

## 🧪 Testing & Validation - Real Homelab Use Cases

**Source:** "My First SIEM Project" series from 0x2A Security Blog

After installation, validate Wazuh is working by running these practical tests:

### Test 1: Failed SSH Login Detection (Brute Force)

**Purpose:** Verify Wazuh detects authentication failures.

**On labhost01:**
```bash
# Attempt SSH with wrong password 5-10 times
ssh wronguser@localhost
# Enter wrong password repeatedly
```

**Check Wazuh Dashboard:**
- Navigate to **Security Events**
- Filter by Rule ID: `5710` (Multiple authentication failures)
- Should see alert: "sshd: authentication failed" with source IP

**What this proves:**
- Wazuh is ingesting auth logs (`/var/log/auth.log`)
- Detection rules are working
- Real-time alerting functions

---

### Test 2: File Integrity Monitoring (FIM)

**Purpose:** Detect unauthorized changes to system files.

**Enable FIM for /etc directory (if not already enabled):**

On labhost01:
```bash
sudo nano /var/ossec/etc/ossec.conf
```

Add inside `<syscheck>` section:
```xml
<directories check_all="yes" realtime="yes">/etc</directories>
```

Restart agent:
```bash
sudo systemctl restart wazuh-agent
```

**Trigger FIM alert:**
```bash
# Create test file in monitored directory
echo "test" | sudo tee /etc/test-wazuh.txt

# Modify it
echo "modified" | sudo tee /etc/test-wazuh.txt

# Delete it
sudo rm /etc/test-wazuh.txt
```

**Check Wazuh Dashboard:**
- Navigate to **File Integrity Monitoring**
- Should see events for: file creation, modification, deletion
- View file hash changes (SHA256)

**What this proves:**
- Real-time file monitoring works
- Detects unauthorized changes to critical system files (passwd, shadow, ssh configs)

---

### Test 3: Vulnerability Detection

**Purpose:** Identify outdated/vulnerable packages on labhost01.

**How it works:**
- Wazuh agent scans installed packages
- Compares against CVE databases
- Reports vulnerabilities automatically

**Check Vulnerability Dashboard:**
1. Navigate to **Vulnerabilities** in Wazuh UI
2. Select `labhost01` agent
3. View CVE list with CVSS scores

**Example vulnerabilities you might see:**
- CVE-2024-XXXX in `openssh-server` (high severity)
- CVE-2023-XXXX in `systemd` (medium severity)

**Remediation workflow:**
```bash
# On labhost01
sudo apt update
sudo apt upgrade -y

# Wait ~5 minutes for Wazuh to rescan
# Vulnerabilities should reduce in dashboard
```

**What this proves:**
- Package vulnerability scanning operational
- Security posture visibility across homelab

---

### Test 4: EICAR Antivirus Test File Detection

**Purpose:** Validate malware/suspicious file detection.

**On labhost01:**
```bash
# Download harmless EICAR test file
wget https://secure.eicar.org/eicar.com

# OR create it manually
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.com
```

**Check Wazuh Dashboard:**
- Navigate to **Security Events**
- Filter by: "suspicious file" or "eicar"
- Should see alert: File integrity monitoring detected change in file '/path/to/eicar.com'

**What this proves:**
- File integrity monitoring catches new suspicious files
- Integration with threat intelligence works

---

### Test 5: Docker Container Monitoring (Advanced)

**Purpose:** Monitor container lifecycle events on labhost01.

**Requirements:**
- Python 3 on labhost01 agent
- Docker listener enabled in Wazuh config

**Enable Docker monitoring:**

On labhost01:
```bash
sudo nano /var/ossec/etc/ossec.conf
```

Add Docker module:
```xml
<wodle name="docker-listener">
  <disabled>no</disabled>
</wodle>
```

Restart agent:
```bash
sudo systemctl restart wazuh-agent
```

**Trigger events:**
```bash
# Start a container
docker run -d --name test-container nginx

# Execute command in container
docker exec test-container whoami

# Stop container
docker stop test-container

# Remove container
docker rm test-container
```

**Check Wazuh Dashboard:**
- Navigate to **Security Events**
- Filter by: "docker" or Rule ID `87900+`
- Should see events for: container start, exec, stop, delete

**What this proves:**
- Container security monitoring operational
- Can detect rogue containers or unauthorized exec commands

---

## 🎯 Key Wazuh Capabilities

### 1. Security Configuration Assessment (SCA)

**What it does:** Evaluates security posture against industry standards.

**Supported benchmarks:**
- CIS Debian Linux Benchmark
- CIS SSH Configuration
- PCI DSS compliance
- NIST 800-53

**Check SCA Dashboard:**
- Navigate to **Security Configuration Assessment**
- Select `labhost01`
- View compliance score (e.g., "78% compliant with CIS Debian 11")
- Review failed checks with remediation steps

---

### 2. Rootkit Detection

**Automatically scans for:**
- Hidden files/directories
- Hidden processes
- Hidden ports
- Known rootkit signatures (Wazuh includes 70+ rootkit signatures)

**Example rootkits detected:**
- TRK (Tiny Rootkit)
- Ligolo
- Volc Rootkit

**Check:**
- Navigate to **Integrity Monitoring** → **Rootkit Detection**
- Any findings show as high-severity alerts

---

### 3. Log Analysis

**Wazuh analyzes logs from:**
- System logs (`/var/log/syslog`)
- Authentication logs (`/var/log/auth.log`)
- Web server logs (Apache, Nginx)
- Custom application logs

**Detection examples:**
- SQL injection attempts
- Directory traversal attacks
- Sudo escalation attempts
- Kernel panics

---

### 4. Active Response (Automated Threat Mitigation)

**Wazuh can automatically:**
- Block attacking IPs via firewall (iptables/ufw)
- Disable user accounts after brute-force
- Quarantine suspicious files
- Restart services after crashes

**Example: Auto-block SSH brute force:**

Edit `/var/ossec/etc/ossec.conf` on labhost00:
```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5710</rules_id>
  <timeout>600</timeout>
</active-response>
```

**What this does:**
- After 5+ failed SSH logins (Rule 5710)
- Automatically blocks source IP for 600 seconds
- Removes block automatically after timeout

---

## 📊 Dashboard Navigation

### Main Sections

**Overview:**
- Global security events count
- Agent status summary
- Top security alerts
- Vulnerability trends

**Security Events:**
- Real-time alert stream
- Filter by severity, rule ID, agent
- Drill down into event details

**Agents:**
- List of all monitored hosts
- Connection status
- OS information
- Last seen timestamp

**Vulnerabilities:**
- CVE list per agent
- CVSS severity scores
- Affected packages
- Remediation links

**File Integrity Monitoring:**
- File changes timeline
- Hash comparisons (before/after)
- User who made change
- Filter by directory

**Security Configuration Assessment:**
- CIS benchmark compliance
- Failed vs passed checks
- Remediation recommendations

**Threat Hunting:**
- Custom queries across all logs
- MITRE ATT&CK technique mapping
- Saved search templates

---

## 🐛 Common Issues & Solutions

### Issue 1: Dashboard shows "Failed to connect to Wazuh indexer"

**Cause:** Indexer still starting up (takes ~1 minute).

**Solution:**
```bash
# Wait and check logs
docker logs wazuh.indexer

# Look for: "started"
```

---

### Issue 2: Agent shows as "Disconnected" in dashboard

**Cause:** Agent can't reach manager on port 1515.

**Debug:**
```bash
# On labhost01 - test connectivity
telnet 192.168.1.100 1515

# Check agent config
sudo cat /var/ossec/etc/ossec.conf | grep address

# Check agent logs
sudo tail -f /var/ossec/logs/ossec.log
```

**Common fixes:**
- Firewall blocking port 1515
- Wrong manager IP in agent config
- Agent service not running

---

### Issue 3: No vulnerability alerts appearing

**Cause:** Vulnerability detector disabled or scanning interval not reached.

**Check:**
```bash
# On labhost00
docker exec wazuh.manager cat /var/ossec/etc/ossec.conf | grep -A 10 vulnerability-detector

# Should show:
# <vulnerability-detector>
#   <enabled>yes</enabled>
```

**Force scan:**
```bash
# On labhost01
sudo /var/ossec/bin/agent_control -r -a
```

---

### Issue 4: High memory usage

**Cause:** Wazuh Indexer is memory-intensive.

**Solutions:**
1. **Reduce retention period:**
   - Default: 90 days of indexed alerts
   - Lower to 30 days if disk/memory limited

2. **Tune Java heap size:**
   Edit `docker-compose.yml`:
   ```yaml
   wazuh.indexer:
     environment:
       - "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g"  # Limit to 2GB
   ```

---

### Issue 5: Agent version mismatch

**Error:** "Agent version must be lower or equal to manager version"

**Cause:** Agent is newer than manager.

**Solution:**
```bash
# On labhost01 - uninstall agent
sudo apt remove wazuh-agent -y

# Reinstall specific version matching manager
sudo apt install wazuh-agent=4.11.2-1 -y
```

**Check versions:**
```bash
# Manager version
docker exec wazuh.manager cat /etc/wazuh-version

# Agent version (on labhost01)
/var/ossec/bin/wazuh-control info | grep VERSION
```

---

## 🔄 Maintenance & Updates

### Updating Wazuh Stack

```bash
# On labhost00
cd ~/wazuh-docker/single-node

# Pull latest images
docker-compose pull

# Recreate containers (data persists in volumes)
docker-compose up -d

# Verify
docker-compose ps
```

**Data persistence:**
- Wazuh Indexer data: `/var/lib/docker/volumes/single-node_wazuh-indexer-data`
- Wazuh Manager config: `/var/lib/docker/volumes/single-node_wazuh_etc`

**Data survives:** Container recreation, host reboots

**Data lost if:** Volumes deleted manually

---

### Backup Critical Data

```bash
# Backup Wazuh configuration
docker exec wazuh.manager tar czf /tmp/wazuh-backup.tar.gz /var/ossec/etc
docker cp wazuh.manager:/tmp/wazuh-backup.tar.gz ~/wazuh-backup-$(date +%Y%m%d).tar.gz

# Backup agent keys (for re-registering agents)
docker exec wazuh.manager cat /var/ossec/etc/client.keys > ~/wazuh-client-keys-backup.txt
```

---

## 📚 Next Steps After Installation

### 1. Tune False Positives

**Disable noisy rules:**
```bash
# On labhost00
docker exec -it wazuh.manager bash

# Edit local rules
nano /var/ossec/etc/rules/local_rules.xml
```

Add:
```xml
<group name="local,syslog,">
  <!-- Disable rule 5402 - sudo session opened -->
  <rule id="5402" level="0" overwrite="yes">
    <description>Rule disabled (too noisy in homelab)</description>
  </rule>
</group>
```

Restart manager:
```bash
docker restart wazuh.manager
```

---

### 2. Add More Agents

Install Wazuh agent on:
- **labhost02** - Monitor Deep Thought workloads
- **QNAP NAS** - Detect unauthorized file access
- **Home router/firewall** - Log analysis (if supported)

---

### 3. Custom Detection Rules

**Example: Detect specific command execution**

```xml
<!-- /var/ossec/etc/rules/local_rules.xml -->
<rule id="100100" level="10">
  <if_sid>2902</if_sid>
  <match>^rm -rf /</match>
  <description>Dangerous command detected: rm -rf /</description>
  <mitre>
    <id>T1485</id>  <!-- Data Destruction -->
  </mitre>
</rule>
```

---

### 4. Integrate with External Tools

**Connect Wazuh to:**
- **Slack** - Send high-severity alerts to Slack channel
- **Email** - Alert notifications via SMTP
- **TheHive** - Incident response platform integration
- **Shuffle** - SOAR (Security Orchestration, Automation, Response)

---

### 5. Advanced Testing with Atomic Red Team

**Purpose:** Simulate real attack techniques to validate detections.

**Install Atomic Red Team:**
```bash
# On labhost01
git clone https://github.com/redcanaryco/invoke-atomicredteam.git
```

**Run test:**
```powershell
# Example: Test credential dumping detection
Invoke-AtomicTest T1003.001 -ShowDetailsBrief
```

**Check Wazuh:** Should alert on LSASS access, credential dumping attempts.

---

## 🎓 Learning Resources

**Official Documentation:**
- Wazuh Documentation: https://documentation.wazuh.com
- Docker Deployment Guide: https://documentation.wazuh.com/current/deployment-options/docker/
- Rule Documentation: https://documentation.wazuh.com/current/user-manual/ruleset/

**Homelab Implementations:**
- 0x2A Security Blog - SIEM Testing Series: https://0x2asecurity.com/siem-engineering/
- "How I Built a Free SIEM in My Homelab" (Medium, March 2026)

**Detection Engineering:**
- MITRE ATT&CK Framework: https://attack.mitre.org
- Atomic Red Team Tests: https://github.com/redcanaryco/atomic-red-team

---

## 🎯 Success Criteria

After completing this deployment, you should have:

- [x] Wazuh server running on labhost00 (Manager, Indexer, Dashboard)
- [x] Wazuh agent installed and connected on labhost01
- [x] Dashboard accessible at `https://labhost00.taild6529.ts.net:8443`
- [x] Failed SSH login detection working
- [x] File integrity monitoring active on `/etc`
- [x] Vulnerability scan results visible for labhost01
- [x] Agent showing as "Active" in dashboard
- [x] Default passwords changed

---

## 🔮 Future Enhancements

**Phase V Integration:**
- Add Authentik SSO for Wazuh Dashboard
- Configure Traefik reverse proxy: `https://wazuh.labhost00.jg-labs.dev`
- Integrate alerts with Grafana dashboards
- Export metrics to Prometheus for uptime monitoring

**Advanced Use Cases:**
- Monitor Kafka/Redpanda security events
- Container security policies for Docker workloads
- Custom rules for homelab-specific threats
- Automated incident response playbooks

---

**Wazuh transforms your homelab from "hoping nothing bad happens" to "knowing instantly when something suspicious occurs."** 🛡️

Let the security monitoring begin! 🚀
