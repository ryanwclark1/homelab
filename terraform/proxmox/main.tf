# Main Terraform configuration for Proxmox K3s cluster
# This configuration creates VMs matching your existing inventory.json

# Create all K3s VMs using the reusable module
module "k3s_vms" {
  source   = "../modules/k3s-vm"
  for_each = local.vms

  # VM Configuration
  target_node    = each.value.target_node
  vmid           = each.value.vmid
  name           = each.value.name
  clone_template = var.template_name

  # Resources
  cores             = each.value.cores
  sockets           = each.value.sockets
  memory            = each.value.memory
  disk_size         = each.value.disk_size
  storage           = each.value.storage
  storage_disk_size = lookup(each.value, "storage_disk_size", null)

  # Network
  ip_address   = "${each.value.ip}/${var.cidr_mask}"
  gateway      = var.gateway
  nameserver   = var.nameserver
  searchdomain = var.searchdomain

  # Cloud-Init
  ci_user           = var.ci_user
  ci_password       = var.ci_password
  ci_ssh_public_key = var.ci_ssh_public_key

  # K3s Role
  role = each.value.role

  # Tags
  tags = concat(var.common_tags, ["k3s-cluster"])

  # Lifecycle - don't auto-start to allow manual K3s initialization
  start_on_create = false
  start_on_boot   = true
}
