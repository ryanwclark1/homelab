# TrueNAS Integration Guide

Complete guide for managing TrueNAS storage servers with Ansible.

## Overview

This integration provides:
- Automated TrueNAS configuration via API
- Dataset and share management
- Snapshot and scrub scheduling
- NFS and SMB share configuration
- Health monitoring and alerts

## Prerequisites

1. **TrueNAS Server**
   - TrueNAS SCALE or TrueNAS CORE
   - API v2.0 access
   - Network connectivity from Ansible control node

2. **API Key**
   - Generate in TrueNAS UI: Settings → API Keys
   - Copy the API key (shown only once!)

3. **Ansible Collections**
   ```bash
   cd ansible
   make install-collections
   ```

## Quick Start

### 1. Configure Inventory

Edit `inventories/storage/truenas.yml`:

```yaml
truenas_servers:
  hosts:
    truenas01:
      ansible_host: 10.10.100.50
      truenas_api_url: "http://10.10.100.50/api/v2.0"
      truenas_api_key: "{{ vault_truenas_api_key }}"
```

### 2. Store API Key Securely

Create encrypted vault file:

```bash
# Create vault password file
echo "your-vault-password" > ~/.ansible-vault-pass

# Create encrypted vars
ansible-vault create group_vars/truenas_servers/vault.yml
```

Add to `vault.yml`:
```yaml
vault_truenas_api_key: "1-abc123def456..."
```

Update `ansible.cfg`:
```ini
[defaults]
vault_password_file = ~/.ansible-vault-pass
```

### 3. Test Connectivity

```bash
make truenas-health
```

### 4. Configure TrueNAS

```bash
make truenas-setup
```

## Configuration

### Datasets

Define datasets in `group_vars/truenas_servers/main.yml`:

```yaml
truenas_datasets:
  - name: tank/proxmox
    compression: lz4
    quota: 1T
    record_size: 128K

  - name: tank/backup
    compression: gzip-9
    quota: 5T
    record_size: 1M

  - name: tank/media
    compression: lz4
    quota: 10T
    record_size: 1M
```

### NFS Shares

Configure NFS exports:

```yaml
truenas_nfs_enabled: true

truenas_nfs_shares:
  - path: /mnt/tank/proxmox
    comment: "Proxmox VM storage"
    networks:
      - 10.10.100.0/23
    maproot_user: root
    maproot_group: root

  - path: /mnt/tank/backup
    comment: "Backup storage"
    networks:
      - 10.10.100.0/23
    maproot_user: nobody
    maproot_group: nogroup
```

### SMB Shares

Configure SMB/CIFS shares:

```yaml
truenas_smb_enabled: true
truenas_smb_workgroup: HOMELAB

truenas_smb_shares:
  - name: backups
    path: /mnt/tank/backup
    comment: "Proxmox and host backups"
    ro: false
    guest_ok: false

  - name: media
    path: /mnt/tank/media
    comment: "Media files"
    ro: true
    guest_ok: true
```

### Snapshots

Automated snapshot scheduling:

```yaml
truenas_snapshot_tasks:
  - dataset: tank/proxmox
    recursive: true
    schedule:
      minute: "0"
      hour: "2"
      day_of_month: "*"
    lifetime_value: 7
    lifetime_unit: DAY

  - dataset: tank/backup
    recursive: true
    schedule:
      minute: "0"
      hour: "3"
      day_of_month: "*"
    lifetime_value: 30
    lifetime_unit: DAY
```

### Scrub Tasks

ZFS pool scrubbing:

```yaml
truenas_scrub_tasks:
  - pool: tank
    schedule:
      minute: "0"
      hour: "3"
      day_of_week: "7"  # Sunday
    threshold: 35
```

## Playbooks

### truenas-setup.yml

Full TrueNAS configuration:

```bash
# Configure all TrueNAS servers
ansible-playbook playbooks/truenas-setup.yml

# With specific tags
ansible-playbook playbooks/truenas-setup.yml --tags nfs,smb

# Dry run
ansible-playbook playbooks/truenas-setup.yml --check
```

**Available tags:**
- `network` - Network configuration
- `storage` - Storage pools
- `datasets` - Dataset creation
- `nfs` - NFS configuration
- `smb` - SMB configuration
- `snapshots` - Snapshot tasks
- `scrub` - Scrub tasks
- `alerts` - Alert configuration

### truenas-health.yml

Health check and monitoring:

```bash
# Check TrueNAS health
ansible-playbook playbooks/truenas-health.yml

# Save report
ansible-playbook playbooks/truenas-health.yml > truenas-health.txt
```

Checks:
- System info and uptime
- Storage pool status
- Active alerts
- Service status

## Makefile Commands

```bash
# Install required collections
make install-collections

# Configure TrueNAS
make truenas-setup

# Health check
make truenas-health

# System info
make truenas-info
```

## Integration with Proxmox

### Use TrueNAS for Proxmox Storage

1. **Create NFS share on TrueNAS:**

```yaml
# In group_vars/truenas_servers/main.yml
truenas_datasets:
  - name: tank/proxmox-vms
    compression: lz4
    quota: 2T
    record_size: 128K

truenas_nfs_shares:
  - path: /mnt/tank/proxmox-vms
    networks:
      - 10.10.100.0/23
    maproot_user: root
    maproot_group: root
```

2. **Mount on Proxmox nodes:**

```yaml
# In ansible/roles/proxmox_storage/tasks/main.yml
- name: Mount TrueNAS NFS storage
  mount:
    path: /mnt/truenas-vms
    src: "10.10.100.50:/mnt/tank/proxmox-vms"
    fstype: nfs
    opts: "vers=4,rw,sync"
    state: mounted
```

3. **Add to Proxmox storage:**

```bash
# On Proxmox nodes
pvesm add nfs truenas-vms \
  --server 10.10.100.50 \
  --export /mnt/tank/proxmox-vms \
  --content images,rootdir
```

## Use Cases

### Centralized VM Storage

```yaml
truenas_datasets:
  - name: tank/proxmox-vms
    compression: lz4
    quota: 5T
    record_size: 128K  # Optimal for VMs

truenas_nfs_shares:
  - path: /mnt/tank/proxmox-vms
    networks:
      - 10.10.100.0/23
    maproot_user: root
```

### Backup Target

```yaml
truenas_datasets:
  - name: tank/backups
    compression: gzip-9  # High compression for backups
    quota: 10T
    record_size: 1M

truenas_smb_shares:
  - name: backups
    path: /mnt/tank/backups
    ro: false
    guest_ok: false
```

### Media Server

```yaml
truenas_datasets:
  - name: tank/media
    compression: lz4
    quota: 20T
    record_size: 1M  # Optimal for large files

truenas_smb_shares:
  - name: media
    path: /mnt/tank/media
    ro: true
    guest_ok: true
```

## Advanced Configuration

### Replication

TrueNAS-to-TrueNAS replication for disaster recovery:

```yaml
# Not yet implemented in role
# Configure manually via TrueNAS UI or API
```

### iSCSI

Block storage for VMs:

```yaml
# Configure iSCSI targets
# Add to role if needed
```

### Cloud Sync

Backup to cloud storage:

```yaml
# Configure cloud sync tasks
# Add to role if needed
```

## Troubleshooting

### API Connection Issues

```bash
# Test API connectivity
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://10.10.100.50/api/v2.0/system/info

# Check TrueNAS service
systemctl status middlewared  # TrueNAS SCALE
```

### Collection Issues

```bash
# Reinstall collections
make install-collections

# Verify installation
ansible-galaxy collection list | grep truenas
```

### Permission Issues

```yaml
# For NFS root access
maproot_user: root
maproot_group: root

# For NFS user access
mapall_user: nobody
mapall_group: nogroup
```

### Performance Tuning

```yaml
# For VMs
record_size: 128K
compression: lz4

# For databases
record_size: 8K
compression: lz4

# For media
record_size: 1M
compression: lz4

# For backups
record_size: 1M
compression: gzip-9
```

## Best Practices

1. **Use API Keys** - More secure than username/password
2. **Encrypt Secrets** - Use Ansible Vault for API keys
3. **Regular Scrubs** - Weekly or monthly
4. **Snapshot Strategy** - Daily for VMs, weekly for backups
5. **Monitor Alerts** - Check regularly for pool issues
6. **Document Shares** - Use descriptive comments
7. **Test Restores** - Verify backups actually work

## Monitoring

### Integrate with Prometheus

```yaml
# Enable Prometheus exporter on TrueNAS
# Configure in TrueNAS UI or via API
```

### Alert Integration

```yaml
# Configure email alerts
# Add webhook for Slack/Discord
# Integrate with monitoring stack
```

## References

- [TrueNAS API Documentation](https://www.truenas.com/docs/api/)
- [Ansible Collection: arensb.truenas](https://galaxy.ansible.com/ui/repo/published/arensb/truenas/)
- [TrueNAS SCALE Documentation](https://www.truenas.com/docs/scale/)
- [ZFS Best Practices](https://openzfs.github.io/openzfs-docs/)

## Example Complete Configuration

```yaml
---
# group_vars/truenas_servers/main.yml

# API settings
truenas_api_timeout: 60
truenas_validate_certs: false

# Network
truenas_dns_servers:
  - 10.10.100.1
  - 1.1.1.1

# Datasets
truenas_datasets:
  - name: tank/proxmox-vms
    compression: lz4
    quota: 2T
    record_size: 128K

  - name: tank/backups
    compression: gzip-9
    quota: 5T
    record_size: 1M

# NFS
truenas_nfs_enabled: true
truenas_nfs_shares:
  - path: /mnt/tank/proxmox-vms
    networks:
      - 10.10.100.0/23
    maproot_user: root
    maproot_group: root

# Snapshots
truenas_snapshot_tasks:
  - dataset: tank/proxmox-vms
    recursive: true
    schedule:
      minute: "0"
      hour: "2"
    lifetime_value: 7
    lifetime_unit: DAY

# Scrub
truenas_scrub_tasks:
  - pool: tank
    schedule:
      minute: "0"
      hour: "3"
      day_of_week: "7"
    threshold: 35
```

## Support

For TrueNAS-specific issues:
1. Check TrueNAS logs: System → Advanced → Logs
2. Verify API access in TrueNAS UI
3. Test with `make truenas-health`
4. Review Ansible verbose output: `ansible-playbook playbooks/truenas-setup.yml -vvv`
