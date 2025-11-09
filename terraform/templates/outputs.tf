output "template_id" {
  description = "Template VM ID"
  value       = proxmox_vm_qemu.template.vmid
}

output "template_name" {
  description = "Template name"
  value       = proxmox_vm_qemu.template.name
}

output "template_node" {
  description = "Node where template is stored"
  value       = proxmox_vm_qemu.template.target_node
}

output "cloud_image_path" {
  description = "Path to cloud image on Proxmox node"
  value       = local.cloud_image_path
}

output "template_info" {
  description = "Template information for VM deployment"
  value = {
    id   = proxmox_vm_qemu.template.vmid
    name = proxmox_vm_qemu.template.name
    node = proxmox_vm_qemu.template.target_node
  }
}
