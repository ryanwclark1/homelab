# Homelab Terraform Configuration

Infrastructure as Code (IaC) for managing Proxmox-based homelab infrastructure using Terraform.

## Overview

This Terraform configuration manages your K3s cluster VMs across multiple Proxmox nodes:

- **6 Proxmox nodes**: james, andrew, john, peter, judas, philip
- **14 K3s VMs**: 6 masters, 5 workers, 3 storage nodes
- **Network**: 10.10.101.0/23 subnet
- **Domain**: techcasa.io

## Directory Structure

```
terraform/
├── deploy.sh             # Orchestration script (template + VMs)
├── templates/            # Cloud-init template configuration
│   ├── versions.tf       # Terraform version requirements
│   ├── variables.tf      # Template variables
│   ├── main.tf           # Template resource definition
│   ├── outputs.tf        # Template outputs
│   ├── Makefile          # Template management commands
│   ├── README.md         # Template documentation
│   └── terraform.tfvars.example  # Example configuration
│
├── proxmox/              # Main Proxmox VM configuration
│   ├── versions.tf       # Terraform and provider versions
│   ├── providers.tf      # Proxmox provider configuration
│   ├── variables.tf      # Input variables
│   ├── locals.tf         # VM definitions from inventory.json
│   ├── main.tf           # Main resource definitions
│   ├── outputs.tf        # Output values
│   ├── Makefile          # Helper commands
│   ├── terraform.tfvars.example  # Example variables file
│   ├── scripts/          # Helper scripts
│   │   ├── create-api-token.sh   # Create Proxmox API token
│   │   └── import-existing.sh    # Import existing VMs
│   └── templates/        # Template files
│       └── ansible_inventory.tpl # Ansible inventory template
│
└── modules/
    └── k3s-vm/           # Reusable K3s VM module
        ├── main.tf       # Module resources
        ├── variables.tf  # Module variables
        └── outputs.tf    # Module outputs
```

## Prerequisites

1. **Terraform** >= 1.5.0
   ```bash
   # Install on Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Proxmox VE** 7.x or 8.x with:
   - API token or user credentials
   - Network connectivity to Proxmox API
   - SSH access to Proxmox nodes

3. **SSH Key Pair** for VM access
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ssh-copy-id root@james.techcasa.io
   ```

4. **jq** (optional, for JSON parsing)
   ```bash
   apt install jq  # Debian/Ubuntu
   ```

## Quick Start

### Automated Deployment (Recommended)

Use the orchestration script for end-to-end deployment:

```bash
cd terraform

# 1. Create Proxmox API token
ssh root@james < proxmox/scripts/create-api-token.sh

# 2. Configure both template and VM variables
cp templates/terraform.tfvars.example templates/terraform.tfvars
cp proxmox/terraform.tfvars.example proxmox/terraform.tfvars

# Edit both files with your credentials
vim templates/terraform.tfvars
vim proxmox/terraform.tfvars

# 3. Check prerequisites
./deploy.sh check

# 4. Deploy everything (template + VMs)
./deploy.sh all
```

### Manual Deployment (Step-by-Step)

#### Step 1: Create Proxmox API Token

```bash
# Use the helper script
scp proxmox/scripts/create-api-token.sh root@james:/tmp/
ssh root@james "bash /tmp/create-api-token.sh"

# Or create via Proxmox UI:
# Datacenter -> Permissions -> API Tokens -> Add
# User: root@pam, Token ID: terraform, Privilege Separation: No
```

#### Step 2: Create Cloud-Init Template

```bash
cd terraform/templates

# Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Add API credentials and SSH key

# Create template
make init
make plan
make apply
make info
```

This creates template VM (ID 5001) on james with Debian 12 cloud image.

#### Step 3: Deploy VMs

```bash
cd ../proxmox

# Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Add credentials and settings

# Deploy
make init
make plan
make apply

# Generate Ansible inventory
make inventory
```

## Cloud-Init Template Management

The infrastructure requires a cloud-init template (ID 5001) that VMs will be cloned from.

### Automated Template Creation (Recommended)

Terraform now handles template creation automatically:

```bash
cd terraform/templates
make deploy
```

This will:
1. Download Debian 12 cloud image to james
2. Verify image checksum (SHA512)
3. Create template VM with UEFI, cloud-init, and virtio drivers
4. Configure serial console and networking

See [templates/README.md](templates/README.md) for detailed documentation.

### Alternative: Manual Template Creation

If you prefer manual setup or need a different OS:

```bash
# SSH to Proxmox node
ssh root@james

# Download cloud image
cd /var/lib/vz/template/iso/
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Create and configure template
qm create 5001 --name "debian-bookworm-cloudinit" \
  --ostype l26 --memory 4096 --cpu host --socket 1 --core 2 \
  --bios ovmf --machine q35 --scsihw virtio-scsi-pci \
  --efidisk0 tank:0,pre-enrolled-keys=0 \
  --net0 virtio,bridge=vmbr0

qm set 5001 --scsi0 tank:0,ssd=on,import-from=/var/lib/vz/template/iso/debian-12-generic-amd64.qcow2
qm set 5001 --ide2 tank:cloudinit --boot order=scsi0
qm set 5001 --vga serial0 --serial0 socket --ipconfig0 ip=dhcp
qm template 5001
```

## Usage

### Managing VMs

```bash
# Show what will be created
make plan

# Create all VMs
make apply

# Create specific VM
make apply-vm VM=k3s-node01

# Destroy specific VM
make destroy-vm VM=k3s-node01

# Destroy all VMs
make destroy
```

### Viewing Information

```bash
# Show all outputs
make output

# Show cluster info
make cluster-info

# Show SSH commands
make ssh-commands

# Show current state
make show
```

### Working with Existing VMs

If you already have VMs created manually and want to manage them with Terraform:

```bash
# Import all existing VMs
./scripts/import-existing.sh

# Or import specific VM
terraform import 'module.k3s_vms["k3s-node01"].proxmox_vm_qemu.vm' james/qemu/221
```

## Configuration

### VM Inventory

VMs are defined in `locals.tf` based on your existing `inventory.json`. To add a new VM:

```hcl
# In locals.tf, add to the vms map:
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

### Module Usage

The k3s-vm module is reusable for creating VMs:

```hcl
module "custom_vm" {
  source = "../modules/k3s-vm"

  target_node       = "james"
  vmid              = 300
  name              = "custom-vm"
  clone_template    = "debian-bookworm-cloudinit"

  cores   = 2
  sockets = 1
  memory  = 4096

  ip_address   = "10.10.101.240/23"
  gateway      = "10.10.100.1"
  nameserver   = "10.10.100.1"
  searchdomain = "techcasa.io"

  ci_user           = "administrator"
  ci_password       = var.ci_password
  ci_ssh_public_key = var.ci_ssh_public_key

  role = "worker"
  tags = ["terraform", "custom"]
}
```

## Outputs

After applying, Terraform provides useful outputs:

```bash
# All VM information
terraform output all_vms

# Master nodes only
terraform output master_nodes

# K3s cluster info
terraform output k3s_cluster_info

# Ansible inventory (formatted)
terraform output -raw ansible_inventory > inventory.ini
```

## Integration with Existing Tools

### Ansible Integration

Generate Ansible inventory from Terraform:

```bash
make inventory
# Creates ansible_inventory.ini

# Use with ansible
ansible -i ansible_inventory.ini all -m ping
```

### K3s Deployment

After VMs are created, deploy K3s:

```bash
# Start all VMs
for node in k3s-node{01..14}; do
  ssh administrator@$node "sudo systemctl start qemu-guest-agent"
done

# Use your existing cloud-init/initialize_nodes.sh script
# or Ansible playbooks with the generated inventory
```

## Troubleshooting

### Common Issues

**Issue**: "Error: error creating VM: error creating Cloud-Init drive"
```bash
# Solution: Ensure cloud-init is configured in template
qm set 5001 --ide2 tank:cloudinit
```

**Issue**: "Error: 401 authentication failure"
```bash
# Solution: Verify API token
pveum user token list root@pam

# Recreate if needed
pveum user token remove root@pam terraform
pveum user token add root@pam terraform --privsep 0
```

**Issue**: "Error: VM with ID already exists"
```bash
# Solution: Import existing VM or use different VMID
terraform import 'module.k3s_vms["k3s-node01"].proxmox_vm_qemu.vm' james/qemu/221
```

**Issue**: "timeout waiting for SSH"
```bash
# Solution: Check VM network configuration and cloud-init logs
ssh administrator@<vm-ip>
sudo cloud-init status --wait
sudo journalctl -u cloud-init
```

### Debugging

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
terraform plan

# Provider-specific debugging
export PM_LOG_ENABLE=true
export PM_LOG_LEVELS="debug"
```

## Best Practices

1. **Always review plans before applying**
   ```bash
   make plan
   # Review output carefully
   make apply
   ```

2. **Use version control**
   ```bash
   git add terraform/
   git commit -m "Add VM k3s-node15"
   ```

3. **Back up state files**
   ```bash
   # Consider using remote state (S3, Terraform Cloud)
   # Uncomment backend configuration in versions.tf
   ```

4. **Test changes on single VM first**
   ```bash
   make plan-vm VM=k3s-node01
   make apply-vm VM=k3s-node01
   ```

5. **Tag resources consistently**
   - Use tags for organization and cost tracking
   - Include environment, project, and managed-by tags

## Security Considerations

1. **Protect sensitive files**
   ```bash
   # Never commit these files
   terraform.tfvars
   *.tfstate
   *.tfstate.backup
   ```

2. **Use API tokens instead of passwords**
   - Create limited-scope tokens
   - Rotate tokens regularly
   - Use separate tokens per project

3. **Encrypt state files**
   ```bash
   # Use remote backend with encryption
   # AWS S3, Terraform Cloud, or HashiCorp Consul
   ```

4. **Limit API token permissions**
   ```bash
   # Create role with minimal required permissions
   pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"
   pveum acl modify / --roles TerraformRole --users terraform@pam
   ```

## Migration from Bash Scripts

This Terraform setup replaces your existing bash scripts in:
- `cloud-init/deploy.sh`
- `cloud-init/initialize_nodes.sh`
- Manual `qm clone` and `qm set` commands

**Advantages**:
- Declarative configuration
- State management
- Idempotent operations
- Better change tracking
- Easier collaboration

**Migration steps**:
1. Create cloud-init template (one-time)
2. Configure Terraform variables
3. Run `terraform plan` to preview
4. Either:
   - Import existing VMs: `./scripts/import-existing.sh`
   - Or recreate VMs: `terraform apply`

## Additional Resources

- [Telmate Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Terraform debug logs
3. Check Proxmox logs: `/var/log/pve/`
4. Verify cloud-init logs on VMs: `cloud-init status --long`

## License

This configuration is part of your homelab infrastructure. Adjust as needed for your environment.
