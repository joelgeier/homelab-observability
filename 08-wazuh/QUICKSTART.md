# Wazuh Deployment - Quick Start

**Version:** 1.2.0  
**Last Updated:** 2026-04-09

---

## 🚀 Quick Deployment

```bash
# On labhost00

# 1. Set kernel parameter (CRITICAL - do this first!)
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sysctl vm.max_map_count  # Verify: should show 262144

# 2. Create Docker network
cd ~/homelab-observability
bash scripts/06-create-networks.sh

# 3. Generate SSL certificates
cd ~/homelab-observability/08-wazuh
docker-compose -f generate-certs.yml run --rm generator

# Verify certificates created:
ls -lh certs/
# Should see: admin.pem, wazuh-indexer.pem, wazuh-manager.pem, wazuh-dashboard.pem, root-ca.pem

# 4. Deploy Wazuh stack
docker-compose up -d

# 5. Monitor startup (~2 minutes)
docker-compose logs -f wazuh-dashboard
# Wait for: "Server running at https://0.0.0.0:5601"
# Press Ctrl+C to exit logs

# 6. Check container status
docker-compose ps
# All containers should show "Up" status (not "Restarting")

# 7. Access dashboard
# URL: https://labhost00.taild6529.ts.net:8443
# Username: admin
# Password: SecretPassword
```

---

## ✅ Verification Checklist

After deployment, verify:

```bash
# Container status
docker ps | grep wazuh
# Should show 3 containers all "Up" (not Restarting)

# Port listening
sudo ss -tlnp | grep 8443
# Should show docker-proxy listening

# Logs (no errors)
docker logs wazuh-indexer --tail=20
docker logs wazuh-manager --tail=20
docker logs wazuh-dashboard --tail=20
# Should NOT see "ENOENT", "access denied", or "FATAL" errors

# Access test
curl -k https://localhost:8443
# Should return HTML (not "connection refused")
```

---

## 🔧 Troubleshooting

### Containers Crash-Looping

**Symptom:**
```bash
docker ps | grep wazuh
# Shows "Restarting (1) X seconds ago"
```

**Check logs:**
```bash
docker logs wazuh-indexer --tail=50
docker logs wazuh-dashboard --tail=50
```

**Common causes:**

1. **Missing certificates**
   ```bash
   # Error in logs: "ENOENT: no such file or directory, open '/usr/share/wazuh-dashboard/certs/dashboard-key.pem'"
   
   # Solution: Generate certificates
   cd ~/homelab-observability/08-wazuh
   docker-compose -f generate-certs.yml run --rm generator
   docker-compose down && docker-compose up -d
   ```

2. **vm.max_map_count not set**
   ```bash
   # Error in logs: "max virtual memory areas vm.max_map_count [65530] is too low"
   
   # Solution: Set kernel parameter
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   docker-compose down && docker-compose up -d
   ```

3. **Certificate permission errors**
   ```bash
   # Error in logs: "access denied (/etc/wazuh-indexer/certs/indexer.pem)"
   
   # Solution: Regenerate certificates
   cd ~/homelab-observability/08-wazuh
   rm -rf certs/
   docker-compose -f generate-certs.yml run --rm generator
   docker-compose down && docker-compose up -d
   ```

---

### Can't Access Dashboard

**Symptom:** Browser shows "Unable to connect"

**Diagnosis:**
```bash
# 1. Check if port is listening
sudo ss -tlnp | grep 8443
# Should show docker-proxy

# 2. Test local access
curl -k https://localhost:8443
# Should return HTML

# 3. Check Tailscale connectivity
ping labhost00.taild6529.ts.net
```

**Solutions:**

- If port not listening → Container not running (check logs)
- If curl works but browser doesn't → Tailscale/firewall issue
- If dashboard still starting → Wait 2 minutes, refresh

---

## 📋 Post-Deployment

### Change Default Passwords

**CRITICAL: Do this immediately!**

See full Wazuh README for password change instructions:
`~/homelab-observability/08-wazuh/README.md`

### Install Agent on labhost01

```bash
# On labhost01
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --dearmor -o /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt-get update

# Replace with labhost00's IP
WAZUH_MANAGER="192.168.1.100" sudo apt-get install wazuh-agent -y

sudo systemctl enable wazuh-agent && sudo systemctl start wazuh-agent
```

**Verify agent connected:**
- Dashboard → Agents → Should see labhost01

---

## 🔄 Maintenance

### Stop/Start

```bash
cd ~/homelab-observability/08-wazuh

# Stop
docker-compose down

# Start
docker-compose up -d

# Restart single service
docker-compose restart wazuh-dashboard
```

### View Logs

```bash
# Follow all logs
docker-compose logs -f

# Specific service
docker-compose logs -f wazuh-dashboard

# Last 100 lines
docker logs wazuh-indexer --tail=100
```

### Update Wazuh

```bash
cd ~/homelab-observability/08-wazuh

# Pull new images
docker-compose pull

# Recreate containers (data persists)
docker-compose up -d
```

---

## 📁 File Structure

```
08-wazuh/
├── docker-compose.yml      # Main deployment (v1.2.0)
├── generate-certs.yml      # Certificate generator
├── certs.yml               # Certificate configuration
├── .env.example            # Environment template
├── certs/                  # SSL certificates (generated)
│   ├── root-ca.pem
│   ├── wazuh-indexer.pem
│   ├── wazuh-manager.pem
│   └── wazuh-dashboard.pem
└── README.md               # Full documentation
```

---

**Next:** Configure File Integrity Monitoring, run security tests, scan labhost01 for vulnerabilities! 🛡️
