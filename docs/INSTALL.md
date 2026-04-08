# labhost00 - Debian Installation Configuration

**Date:** 2026-04-08  
**OS:** Debian 13 (Trixie)  
**Purpose:** Observability and monitoring hub VM on QNAP Virtualization Station

---

## System Identity

| Parameter | Value |
|-----------|-------|
| Hostname | `labhost00` |
| Domain | `jg-labs.dev` |
| FQDN | `labhost00.jg-labs.dev` |

---

## User Accounts

| Account | Purpose | Status |
|---------|---------|--------|
| `root` | System administration | Password set during install |
| `labadmin` | Primary admin user | Created during install |

**Note:** The `labadmin` user provides consistency across all labhosts (labhost00, labhost01, labhost02).

---

## Network Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| IP Address | `192.168.1.100` | Static IP |
| Netmask | `255.255.255.0` | /24 CIDR |
| Gateway | `192.168.1.1` | Residential router |
| DNS Servers | Default (to be updated) | **TODO:** Change to `1.1.1.1`, `8.8.8.8` |
| Interface | `ens18` or `eth0` | VM network adapter |

### IP Address Scheme

```
192.168.1.100 - labhost00 (observability hub - QNAP VM)
192.168.1.101 - labhost01 (stream-lake - HP ProDesk)
192.168.1.102 - labhost02 (deep-thought - HP MicroServer)
```

### Post-Install DNS Fix

After first boot, update DNS to Cloudflare/Google:

```bash
# Temporary fix
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

# Permanent fix - edit network config
sudo nano /etc/network/interfaces
# Add: dns-nameservers 1.1.1.1 8.8.8.8
```

---

## Storage Configuration

### Virtual Disk

| Parameter | Value |
|-----------|-------|
| Device | `/dev/vda` |
| Type | Virtio Block Device |
| Size | 107.4 GB |

### Partitioning Scheme

**Method:** Guided partitioning with LVM (Logical Volume Manager)  
**Layout:** All files in one partition

| Partition | Size | Type | Mount Point | Purpose |
|-----------|------|------|-------------|---------|
| `/dev/vda1` | 1.0 GB | ESP (EFI) | `/boot/efi` | UEFI boot partition |
| `/dev/vda2` | 1.0 GB | ext4 | `/boot` | Boot files (non-LVM) |
| `/dev/vda3` | 105.3 GB | LVM PV | — | LVM Physical Volume |

### LVM Configuration

**Volume Group:** `labhost00-vg`

| Logical Volume | Size | Filesystem | Mount Point | Purpose |
|----------------|------|------------|-------------|---------|
| `root` | 99.9 GB | ext4 | `/` | System and data |
| `swap_1` | 5.4 GB | swap | — | Swap space |

### Rationale for LVM with Single Partition

- ✅ **Flexibility:** Easy to expand `/mnt/data/homelab-observability` as needed
- ✅ **Simplicity:** No need to predict space allocation between partitions
- ✅ **Docker-friendly:** All space available for `/var/lib/docker` and data directories
- ✅ **Snapshots:** LVM enables pre-upgrade snapshots for rollback capability

---

## Software Selection

### Installed During Setup

- ✅ **SSH server** (OpenSSH) - Remote access
- ✅ **Standard system utilities** - Basic tools

### NOT Installed (Intentional)

- ⬜ Desktop environment (GNOME, KDE, Xfce, etc.) - Headless server
- ⬜ Web server (Apache/nginx) - Will use Docker instead
- ⬜ Additional packages - Installed via bootstrap scripts

### Post-Install Software Deployment

All additional software will be installed via homelab-observability bootstrap scripts:

```bash
# Scripts 00-05 install:
00-root-bootstrap.sh    # sudo, labadmin user setup
01-preflight.sh         # Environment validation
02-packages.sh          # 60+ CLI tools (curl, git, btop, etc.)
03-docker.sh            # Docker Engine + Compose
04-tailscale.sh         # Tailscale VPN mesh
05-init-directories.sh  # /mnt/data/homelab-observability structure
```

---

## Installation Summary

### What Was Configured

1. ✅ Static IP: 192.168.1.100
2. ✅ Hostname: labhost00.jg-labs.dev
3. ✅ User: labadmin (consistent with other labhosts)
4. ✅ LVM partitioning (99.9 GB root, 5.4 GB swap)
5. ✅ Minimal server install (SSH + standard utilities)
6. ⚠️ DNS: Default (needs manual update to 1.1.1.1, 8.8.8.8)

### First Boot Checklist

- [ ] Verify network connectivity: `ping 1.1.1.1`
- [ ] Update DNS to Cloudflare/Google
- [ ] Login as root
- [ ] Clone homelab-observability repo or copy bootstrap scripts
- [ ] Run `00-root-bootstrap.sh` as root
- [ ] Login as labadmin
- [ ] Run scripts 01-05 in sequence
- [ ] Reboot after script 04 completes
- [ ] Verify Docker: `docker --version`
- [ ] Verify Tailscale: `tailscale status`

---

## VM Host Information

| Parameter | Value |
|-----------|-------|
| Hypervisor | QNAP Virtualization Station |
| Physical Host | QNAP TVS-h1288X |
| CPU Allocation | TBD |
| RAM Allocation | TBD (minimum 8GB, recommend 16GB) |
| Disk Type | Virtual disk on QNAP storage pool |

---

## Notes

- **Architecture:** x86_64 (amd64)
- **UEFI Boot:** Enabled (ESP partition present)
- **Purpose:** Centralized observability hub for labhost01 and labhost02
- **Persistence:** VM stays running 24/7 on QNAP while compute nodes may be rebuilt
- **Data Location:** All observability data in `/mnt/data/homelab-observability/`

---

## Related Documentation

- [Bootstrap Scripts](../scripts/README.md) - Installation automation
- [Network Topology](../README.md#topology) - Network architecture
- [LGTM Stack](../04-lgtm-stack/README.md) - Phase II deployment plan
