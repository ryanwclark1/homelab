# Cloud-Init Template Management

This directory contains Terraform configuration to create and manage the cloud-init template that all K3s VMs will be cloned from.

## Overview

The template configuration:
1. **Downloads** Debian Bookworm cloud image to Proxmox
2. **Verifies** the image checksum (SHA512)
3. **Creates** a template VM (ID 5001) with:
   - UEFI boot (OVMF)
   - Cloud-init support
   - Virtio drivers
   - Serial console

## Quick Start

```bash
cd terraform/templates

# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Add your Proxmox credentials and SSH key

# 2. Create the template
make init
make plan
make apply

# 3. Verify
make info
```

## What Gets Created

### On Proxmox Node (james)

**Downloaded Files:**
- `/var/lib/vz/template/iso/debian-12-generic-amd64.qcow2` (~300MB)
- `/var/lib/vz/template/iso/SHA512SUMS` (checksum file)

**Template VM:**
- **ID**: 5001
- **Name**: debian-bookworm-cloudinit
- **Storage**: tank
- **Type**: Template (cannot be started, only cloned)

**Configuration:**
- BIOS: OVMF (UEFI)
- Machine: Q35
- CPU: 2 cores
- Memory: 4096 MB
- Disk: 10G (virtio-scsi, SSD emulation)
- Network: virtio on vmbr0
- Cloud-init: Enabled on IDE2

## Usage

### Create Template

First time setup:

```bash
# Initialize and create
make deploy
```

This will:
1. SSH to james.techcasa.io
2. Download Debian cloud image
3. Verify checksum
4. Create template VM
5. Configure cloud-init

### Verify Template

```bash
# Show template info
make info

# Or SSH to Proxmox and check
ssh root@james "qm list | grep 5001"
```

### Update Template

To recreate the template with a newer cloud image:

```bash
# Option A: Manual update
ssh root@james "rm /var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"
make recreate

# Option B: Change cloud_image_url in terraform.tfvars
vim terraform.tfvars  # Update cloud_image_url
make recreate
```

### Delete Template

**⚠️ Warning:** Only delete if no VMs are using this template!

```bash
make destroy

# Also cleanup cloud image (optional)
ssh root@james "rm /var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"
```

## Alternative Cloud Images

The default is Debian 12 (Bookworm), but you can use other images:

### Ubuntu 22.04 LTS

```hcl
# In terraform.tfvars
cloud_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
cloud_image_checksum_url = "https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS"
template_name = "ubuntu-jammy-cloudinit"
```

### Ubuntu 24.04 LTS

```hcl
cloud_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
cloud_image_checksum_url = "https://cloud-images.ubuntu.com/noble/current/SHA256SUMS"
template_name = "ubuntu-noble-cloudinit"
```

### Rocky Linux 9

```hcl
cloud_image_url = "https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
template_name = "rocky9-cloudinit"
```

## Configuration Variables

Key variables in `terraform.tfvars`:

```hcl
# Template location
template_node = "james"        # Which Proxmox node
template_id   = 5001          # VM ID for template

# Cloud image
cloud_image_url = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

# Default settings (inherited by cloned VMs)
ci_user           = "administrator"
ci_ssh_public_key = "ssh-rsa AAA..."
```

## SSH Requirements

The template creation requires SSH access to Proxmox:

```bash
# Test SSH connectivity
ssh root@james.techcasa.io "echo 'Connected successfully'"

# Setup key-based auth if needed
ssh-copy-id root@james.techcasa.io
```

## Workflow Integration

After creating the template, use it with the main VM configuration:

```bash
# 1. Create template
cd terraform/templates
make deploy

# 2. Deploy VMs
cd ../proxmox
make deploy
```

The VMs in `proxmox/` will automatically clone from template ID 5001.

## Troubleshooting

### Download Fails

```bash
# Check connectivity from Proxmox node
ssh root@james "wget --spider https://cloud.debian.org"

# Manual download
ssh root@james "cd /var/lib/vz/template/iso && wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
```

### Checksum Verification Fails

```bash
# Check manually
ssh root@james "cd /var/lib/vz/template/iso && sha512sum -c SHA512SUMS --ignore-missing"

# Re-download if corrupted
ssh root@james "rm /var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"
make apply
```

### Template Already Exists

```bash
# If template exists but not in Terraform state
terraform import proxmox_vm_qemu.template james/qemu/5001

# Or destroy existing and recreate
ssh root@james "qm destroy 5001"
make apply
```

### SSH Connection Issues

```bash
# Verify SSH key
ssh-add -l

# Test connection
ssh -v root@james.techcasa.io

# Check DNS
ping james.techcasa.io
```

## Template Customization

To customize the template further, edit `main.tf`:

```hcl
# Add more cores
template_cores = 4

# Increase memory
template_memory = 8192

# Larger default disk
template_disk_size = "20G"

# Add second network
network {
  model  = "virtio"
  bridge = "vmbr1"
  tag    = 100
}
```

## Cloud-Init Behavior

The template includes cloud-init defaults:

- **User**: administrator
- **SSH Key**: From terraform.tfvars
- **Network**: DHCP (overridden on clone)

When VMs are cloned, they override these with specific values from `proxmox/locals.tf`.

## State Management

The template has `prevent_destroy = true` lifecycle policy to prevent accidental deletion.

To force destroy:

```bash
# Edit main.tf and remove prevent_destroy
# Then run
make destroy
```

## Multi-Node Templates

To create templates on multiple nodes:

```bash
# Copy this directory
cp -r templates templates-andrew

# Edit variables
cd templates-andrew
vim terraform.tfvars  # Change template_node = "andrew"

# Create template on andrew node
make deploy
```

This is useful for:
- Faster cloning (local to each node)
- Redundancy
- Testing different OS versions

## Next Steps

After template creation:

1. ✅ Template is ready at james:5001
2. → Deploy VMs: `cd ../proxmox && make apply`
3. → Generate inventory: `make inventory`
4. → Deploy K3s cluster with Ansible

## References

- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Proxmox Cloud-Init Guide](https://pve.proxmox.com/wiki/Cloud-Init_Support)
