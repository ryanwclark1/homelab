# Proxmox K3s Cluster Terraform Configuration

This directory contains Terraform configuration for managing your K3s cluster on Proxmox.

## Quick Reference

### Initial Setup

```bash
# 1. Create API token on Proxmox
ssh root@james "pveum user token add root@pam terraform --privsep 0"

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Add your API credentials

# 3. Initialize Terraform
make init

# 4. Deploy infrastructure
make plan
make apply
```

### Common Commands

```bash
# View cluster info
make cluster-info

# Create specific VM
make apply-vm VM=k3s-node01

# Generate Ansible inventory
make inventory

# Show SSH commands
make ssh-commands

# Format code
make fmt

# Validate configuration
make validate
```

### VM Inventory

Current VMs defined in `locals.tf`:

**Master Nodes** (6):
- k3s-node01 (james) - 10.10.101.221
- k3s-node02 (andrew) - 10.10.101.222
- k3s-node03 (john) - 10.10.101.223
- k3s-node04 (peter) - 10.10.101.224
- k3s-node05 (judas) - 10.10.101.225
- k3s-node06 (philip) - 10.10.101.226

**Worker Nodes** (5):
- k3s-node07 (andrew) - 10.10.101.227
- k3s-node08 (andrew) - 10.10.101.228
- k3s-node09 (john) - 10.10.101.229
- k3s-node10 (john) - 10.10.101.230
- k3s-node11 (peter) - 10.10.101.231
- k3s-node12 (peter) - 10.10.101.232
- k3s-node13 (judas) - 10.10.101.233
- k3s-node14 (judas) - 10.10.101.234

**Storage Nodes** (3):
- k3s-storage17 (andrew) - 10.10.101.237
- k3s-storage18 (john) - 10.10.101.238
- k3s-storage19 (peter) - 10.10.101.239

### Files

- `versions.tf` - Terraform and provider versions
- `providers.tf` - Proxmox provider configuration
- `variables.tf` - Input variable definitions
- `locals.tf` - VM inventory (modify to add/remove VMs)
- `main.tf` - Main resource definitions
- `outputs.tf` - Output values
- `terraform.tfvars` - Your local values (not committed)
- `Makefile` - Helper commands

### Customization

**Add a new VM**:

Edit `locals.tf` and add to the `vms` map:

```hcl
"k3s-node15" = {
  target_node = "philip"
  vmid        = 235
  name        = "k3s-node15"
  ip          = "10.10.101.235"
  cores       = 4
  sockets     = 1
  memory      = 8192
  disk_size   = "10G"
  storage     = "tank"
  role        = "worker"
}
```

Then run:
```bash
make plan
make apply
```

**Modify VM resources**:

Edit the VM entry in `locals.tf`, then:
```bash
make plan-vm VM=k3s-node15
make apply-vm VM=k3s-node15
```

### Import Existing VMs

If you already have VMs created:

```bash
./scripts/import-existing.sh
```

Or manually:
```bash
terraform import 'module.k3s_vms["k3s-node01"].proxmox_vm_qemu.vm' james/qemu/221
```

### Outputs

```bash
# All VMs
terraform output all_vms

# Master nodes
terraform output master_nodes

# Worker nodes
terraform output worker_nodes

# Storage nodes
terraform output storage_nodes

# Cluster info
terraform output k3s_cluster_info

# Ansible inventory
terraform output -raw ansible_inventory
```

### Network Configuration

- **VM Network**: 10.10.101.0/23
- **Gateway**: 10.10.100.1
- **DNS**: 10.10.100.1
- **Domain**: techcasa.io
- **K3s VIP**: 10.10.101.50
- **LoadBalancer Range**: 10.10.101.60-10.10.101.100

### Troubleshooting

**Check VM status**:
```bash
terraform show
```

**Debug provider issues**:
```bash
export TF_LOG=DEBUG
terraform plan
```

**Verify cloud-init on VM**:
```bash
ssh administrator@10.10.101.221
cloud-init status --wait
sudo journalctl -u cloud-init
```

For detailed documentation, see [../README.md](../README.md)
