output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}

output "role" {
  description = "VM role"
  value       = var.role
}

output "target_node" {
  description = "Proxmox node"
  value       = var.target_node
}

output "ssh_host" {
  description = "SSH connection string"
  value       = "${var.ci_user}@${split("/", var.ip_address)[0]}"
}
