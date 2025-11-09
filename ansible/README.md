# Ansible Proxmox Host Management

Ansible automation for managing Proxmox VE hosts in your homelab cluster.

## Overview

This Ansible setup manages:
- **6 Proxmox hosts**: james, andrew, john, peter, judas, philip
- **System configuration**: Common settings, SSH, NTP, DNS
- **Proxmox configuration**: Storage, networking, backups
- **Monitoring**: Health checks, alerts, metrics
- **Maintenance**: Updates, backups, configuration management

## Directory Structure

```
ansible/
├── ansible.cfg                  # Ansible configuration
├── Makefile                     # Helper commands
├── README.md                    # This file
│
├── inventories/
│   └── proxmox/
│       └── hosts.yml            # Proxmox host inventory
│
├── playbooks/
│   ├── site.yml                 # Main configuration playbook
│   ├── update.yml               # System updates
│   ├── health-check.yml         # Cluster health check
│   └── backup.yml               # Backup configurations
│
├── roles/
│   ├── common/                  # Common system configuration
│   ├── proxmox_base/            # Proxmox base setup
│   ├── proxmox_storage/         # Storage management
│   ├── proxmox_network/         # Network configuration
│   └── proxmox_monitoring/      # Monitoring setup
│
├── group_vars/                  # Group variables
├── host_vars/                   # Host-specific variables
└── files/                       # Static files
```

## Prerequisites

1. **Ansible** >= 2.10
   ```bash
   # Install on Debian/Ubuntu
   apt install ansible

   # Or via pip
   pip3 install ansible
   ```

2. **SSH Access** to all Proxmox hosts
   ```bash
   # Test connectivity
   ssh root@james.techcasa.io
   ```

3. **Python 3** on Proxmox hosts (usually pre-installed)

## Quick Start

### 1. Install Collections

```bash
cd ansible

# Install required Ansible Galaxy collections
make install-collections
```

### 2. Generate Secrets

```bash
# Generate strong secrets and create encrypted vault files
make generate-secrets

# Review generated secrets
ansible-vault view group_vars/k3s_cluster/vault.yml
```

### 3. Test Connectivity

```bash
# Ping all hosts
make ping

# Ping specific host
make ping-node NODE=james
```

### 4. Run Health Check

```bash
# Check all hosts
make health

# Check specific host
make health-node NODE=andrew
```

### 5. Configure Cluster

```bash
# Full site configuration
make site

# Configure specific host
make site-node NODE=john
```

## Secrets Management

All sensitive data is managed with Ansible Vault. See [SECRETS.md](SECRETS.md) for complete guide.

### Quick Reference

```bash
# Generate secrets
make generate-secrets

# View encrypted secrets
ansible-vault view group_vars/k3s_cluster/vault.yml

# Edit encrypted secrets
ansible-vault edit group_vars/k3s_cluster/vault.yml
```

## Common Operations

### System Updates

```bash
# Update all hosts (one at a time)
make update

# Update specific host
make update-node NODE=peter
```

Updates are performed **serially** (one node at a time) to avoid cluster disruption.

### Backups

```bash
# Backup all hosts
make backup

# Backup specific host
make backup-node NODE=judas
```

Backs up:
- Network configuration
- Proxmox cluster config
- VM/CT configurations
- Storage settings

### Health Checks

```bash
# Check all hosts
make health

# Check specific host
make health-node NODE=philip
```

Verifies:
- Proxmox services
- Cluster status
- Storage availability
- System resources
- Running VMs/CTs

### Ad-hoc Commands

```bash
# Run command on all hosts
make cmd CMD="uptime"

# Run command on specific host
make cmd-node NODE=james CMD="df -h"
```

### Backup Verification

```bash
# Verify all backups
make verify-backups

# Check Proxmox backups
ansible proxmox_cluster -m find -a "paths=/var/backups/proxmox age=-7d"

# Check TrueNAS snapshots
make truenas-health
```

### Monitoring

```bash
# Deploy monitoring stack to K3s
make k3s-monitoring

# Access Grafana (after deployment)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# View Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

## Playbooks

### site.yml - Main Configuration

Full cluster configuration including all roles:

```bash
# Configure entire cluster
ansible-playbook playbooks/site.yml

# Configure with specific tags
ansible-playbook playbooks/site.yml --tags common,storage

# Dry run
ansible-playbook playbooks/site.yml --check
```

**Available tags:**
- `common` - Common system configuration
- `proxmox` - Proxmox-specific configuration
- `base` - Base Proxmox setup
- `storage` - Storage configuration
- `network` - Network configuration
- `monitoring` - Monitoring setup

### update.yml - System Updates

Updates Proxmox hosts with optional reboot:

```bash
# Update without reboot
ansible-playbook playbooks/update.yml

# Update with reboot
ansible-playbook playbooks/update.yml -e reboot_after_update=true

# Update specific host
ansible-playbook playbooks/update.yml --limit james
```

### health-check.yml - Cluster Health

Comprehensive health check:

```bash
# Check all hosts
ansible-playbook playbooks/health-check.yml

# Save report to file
ansible-playbook playbooks/health-check.yml > health-report.txt
```

### backup.yml - Configuration Backup

Backup Proxmox configurations:

```bash
# Backup all hosts
ansible-playbook playbooks/backup.yml

# Include VM backups (using vzdump)
ansible-playbook playbooks/backup.yml -e backup_vms=true
```

## Roles

### common

Base system configuration for all hosts:
- Package installation
- Timezone/NTP configuration
- SSH hardening
- DNS configuration
- System limits

### proxmox_base

Proxmox-specific configuration:
- APT repositories (no-subscription)
- Datacenter settings
- vzdump backup configuration
- Enterprise nag removal
- IOMMU configuration (optional)

### proxmox_storage

Storage management:
- ZFS pool monitoring
- ZFS ARC configuration
- SMART monitoring
- Auto-scrub scheduling
- Storage pool configuration

### proxmox_network

Network configuration:
- Bridge configuration
- IP forwarding
- Firewall rules (optional)
- Network interfaces

### proxmox_monitoring

Monitoring and health checks:
- Prometheus exporters
- Health check scripts
- Storage monitoring
- Log rotation

## Inventory

Hosts are organized in `inventories/proxmox/hosts.yml`:

```yaml
proxmox_cluster:          # All Proxmox hosts
  ├── primary_nodes:      # Primary node (james)
  ├── secondary_nodes:    # Secondary node (andrew)
  └── member_nodes:       # Other nodes
```

### Host Variables

Each host has:
- `ansible_host` - IP address
- `proxmox_node_id` - Unique node ID
- `datacenter_role` - primary/secondary/member
- `storage_pools` - ZFS pools

### Group Variables

Common variables in `hosts.yml`:
- Network configuration
- Cluster settings
- Backup settings
- Timezone/NTP

## Configuration

### Customizing Variables

Edit `inventories/proxmox/hosts.yml` to modify:

```yaml
vars:
  # Network
  network_gateway: 10.10.100.1
  dns_servers:
    - 10.10.100.1
    - 1.1.1.1

  # Timezone
  timezone: America/New_York

  # Backup
  backup_enabled: true
  backup_retention: 30
```

### Host-Specific Variables

Create `host_vars/james.yml` for host-specific settings:

```yaml
---
zfs_arc_max: 17179869184  # 16GB for james
enable_iommu: true
custom_setting: value
```

## Advanced Usage

### Limit to Specific Hosts

```bash
# Single host
ansible-playbook playbooks/site.yml --limit james

# Multiple hosts
ansible-playbook playbooks/site.yml --limit james,andrew

# Group
ansible-playbook playbooks/site.yml --limit primary_nodes
```

### Using Tags

```bash
# Only run storage configuration
ansible-playbook playbooks/site.yml --tags storage

# Skip monitoring
ansible-playbook playbooks/site.yml --skip-tags monitoring

# Multiple tags
ansible-playbook playbooks/site.yml --tags "common,base"
```

### Dry Run

```bash
# Check mode (no changes)
ansible-playbook playbooks/site.yml --check

# Diff mode (show changes)
ansible-playbook playbooks/site.yml --diff
```

### Verbose Output

```bash
# Verbose
ansible-playbook playbooks/site.yml -v

# Very verbose
ansible-playbook playbooks/site.yml -vv

# Debug level
ansible-playbook playbooks/site.yml -vvv
```

## Integration with Terraform

This Ansible setup complements the Terraform configuration:

1. **Terraform** manages VM lifecycle (create/destroy VMs)
2. **Ansible** manages Proxmox host configuration

Workflow:
```bash
# 1. Configure Proxmox hosts with Ansible
cd ansible
make site

# 2. Deploy VMs with Terraform
cd ../terraform
./deploy.sh all
```

## Troubleshooting

### Connection Issues

```bash
# Test SSH connectivity
make ping

# Check specific host
ssh root@james.techcasa.io

# Verify inventory
make inventory
```

### Playbook Failures

```bash
# Syntax check
make check

# Run in check mode
ansible-playbook playbooks/site.yml --check

# Increase verbosity
ansible-playbook playbooks/site.yml -vvv
```

### Common Issues

**Issue**: "Failed to connect to host"
```bash
# Solution: Verify SSH keys
ssh-copy-id root@james.techcasa.io
```

**Issue**: "Permission denied"
```bash
# Solution: Check ansible.cfg remote_user and become settings
ansible proxmox_cluster -m command -a "whoami" --become
```

**Issue**: "Module not found"
```bash
# Solution: Install required Python modules on Proxmox hosts
ansible proxmox_cluster -m apt -a "name=python3-pip state=present"
```

## Best Practices

1. **Always test first**
   ```bash
   ansible-playbook playbooks/site.yml --check --diff
   ```

2. **Use limits for risky operations**
   ```bash
   ansible-playbook playbooks/update.yml --limit james
   ```

3. **Backup before major changes**
   ```bash
   make backup
   ```

4. **Run health checks regularly**
   ```bash
   make health
   ```

5. **Update serially, not in parallel**
   - Updates run one host at a time (`serial: 1`)
   - Prevents cluster-wide disruption

## Scheduled Maintenance

Consider scheduling regular maintenance:

```bash
# Weekly health check
0 8 * * 1 cd /path/to/ansible && make health > /var/log/cluster-health-weekly.log

# Monthly updates
0 3 1 * * cd /path/to/ansible && make update

# Daily backups
0 2 * * * cd /path/to/ansible && make backup
```

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## Support

For issues or questions:
1. Check playbook syntax: `make check`
2. Run in verbose mode: `ansible-playbook playbooks/site.yml -vvv`
3. Review logs: `cat ansible.log`
4. Test individual tasks manually on hosts

## Summary

This Ansible setup provides:
✅ Complete Proxmox host management
✅ Automated updates and backups
✅ Health monitoring and alerts
✅ Network and storage configuration
✅ Integration with Terraform
✅ Safe, serial operations
✅ Comprehensive documentation

Use `make help` to see all available commands.
