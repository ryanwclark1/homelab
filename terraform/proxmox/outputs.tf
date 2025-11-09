# Output important information about the created VMs

output "all_vms" {
  description = "All created VMs with their details"
  value = {
    for k, v in module.k3s_vms : k => {
      id          = v.vm_id
      name        = v.vm_name
      ip          = v.ip_address
      role        = v.role
      target_node = v.target_node
      ssh_host    = v.ssh_host
    }
  }
}

output "master_nodes" {
  description = "Master node VMs"
  value = {
    for k, v in module.k3s_vms : k => {
      ip       = v.ip_address
      ssh_host = v.ssh_host
    } if v.role == "master"
  }
}

output "worker_nodes" {
  description = "Worker node VMs"
  value = {
    for k, v in module.k3s_vms : k => {
      ip       = v.ip_address
      ssh_host = v.ssh_host
    } if v.role == "worker"
  }
}

output "storage_nodes" {
  description = "Storage node VMs"
  value = {
    for k, v in module.k3s_vms : k => {
      ip       = v.ip_address
      ssh_host = v.ssh_host
    } if v.role == "storage"
  }
}

output "k3s_cluster_info" {
  description = "K3s cluster configuration information"
  value = {
    master_count  = length([for v in module.k3s_vms : v if v.role == "master"])
    worker_count  = length([for v in module.k3s_vms : v if v.role == "worker"])
    storage_count = length([for v in module.k3s_vms : v if v.role == "storage"])
    vip           = var.k3s_vip
    lb_range      = var.k3s_lb_range
    version       = var.k3s_version
  }
}

output "ansible_inventory" {
  description = "Ansible inventory format for K3s nodes"
  value = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    master_nodes  = { for k, v in module.k3s_vms : k => v if v.role == "master" }
    worker_nodes  = { for k, v in module.k3s_vms : k => v if v.role == "worker" }
    storage_nodes = { for k, v in module.k3s_vms : k => v if v.role == "storage" }
  })
  sensitive = false
}

output "ssh_commands" {
  description = "SSH commands to connect to each node"
  value = {
    for k, v in module.k3s_vms : k => "ssh ${v.ssh_host}"
  }
}
