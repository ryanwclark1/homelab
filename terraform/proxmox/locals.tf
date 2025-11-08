# Local variables derived from inventory.json
# These VMs match your existing homelab infrastructure

locals {
  # K3s cluster VMs based on inventory.json
  vms = {
    # James node - 10.10.100.192
    "k3s-node01" = {
      target_node      = "james"
      vmid             = 221
      name             = "k3s-node01"
      ip               = "10.10.101.221"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }

    # Andrew node - 10.10.100.193
    "k3s-node02" = {
      target_node      = "andrew"
      vmid             = 222
      name             = "k3s-node02"
      ip               = "10.10.101.222"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }
    "k3s-node07" = {
      target_node      = "andrew"
      vmid             = 227
      name             = "k3s-node07"
      ip               = "10.10.101.227"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-node08" = {
      target_node      = "andrew"
      vmid             = 228
      name             = "k3s-node08"
      ip               = "10.10.101.228"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-storage17" = {
      target_node       = "andrew"
      vmid              = 237
      name              = "k3s-storage17"
      ip                = "10.10.101.237"
      cores             = 4
      sockets           = 1
      memory            = 8192
      disk_size         = "10G"
      storage           = "tank"
      storage_disk_size = "200G"
      role              = "storage"
    }

    # John node - 10.10.100.191
    "k3s-node03" = {
      target_node      = "john"
      vmid             = 223
      name             = "k3s-node03"
      ip               = "10.10.101.223"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }
    "k3s-node09" = {
      target_node      = "john"
      vmid             = 229
      name             = "k3s-node09"
      ip               = "10.10.101.229"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-node10" = {
      target_node      = "john"
      vmid             = 230
      name             = "k3s-node10"
      ip               = "10.10.101.230"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-storage18" = {
      target_node       = "john"
      vmid              = 238
      name              = "k3s-storage18"
      ip                = "10.10.101.238"
      cores             = 4
      sockets           = 1
      memory            = 8192
      disk_size         = "10G"
      storage           = "tank"
      storage_disk_size = "200G"
      role              = "storage"
    }

    # Peter node - 10.10.100.190
    "k3s-node04" = {
      target_node      = "peter"
      vmid             = 224
      name             = "k3s-node04"
      ip               = "10.10.101.224"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }
    "k3s-node11" = {
      target_node      = "peter"
      vmid             = 231
      name             = "k3s-node11"
      ip               = "10.10.101.231"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-node12" = {
      target_node      = "peter"
      vmid             = 232
      name             = "k3s-node12"
      ip               = "10.10.101.232"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-storage19" = {
      target_node       = "peter"
      vmid              = 239
      name              = "k3s-storage19"
      ip                = "10.10.101.239"
      cores             = 4
      sockets           = 1
      memory            = 8192
      disk_size         = "10G"
      storage           = "tank"
      storage_disk_size = "200G"
      role              = "storage"
    }

    # Judas node - 10.10.100.194
    "k3s-node05" = {
      target_node      = "judas"
      vmid             = 225
      name             = "k3s-node05"
      ip               = "10.10.101.225"
      cores            = 4
      sockets          = 2
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }
    "k3s-node13" = {
      target_node      = "judas"
      vmid             = 233
      name             = "k3s-node13"
      ip               = "10.10.101.233"
      cores            = 4
      sockets          = 2
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }
    "k3s-node14" = {
      target_node      = "judas"
      vmid             = 234
      name             = "k3s-node14"
      ip               = "10.10.101.234"
      cores            = 4
      sockets          = 2
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "worker"
    }

    # Philip node - 10.10.100.195
    "k3s-node06" = {
      target_node      = "philip"
      vmid             = 226
      name             = "k3s-node06"
      ip               = "10.10.101.226"
      cores            = 4
      sockets          = 1
      memory           = 8192
      disk_size        = "10G"
      storage          = "tank"
      role             = "master"
    }
  }

  # Organize VMs by role
  master_vms = { for k, v in local.vms : k => v if v.role == "master" }
  worker_vms = { for k, v in local.vms : k => v if v.role == "worker" }
  storage_vms = { for k, v in local.vms : k => v if v.role == "storage" }

  # Master node IPs for K3s cluster init
  master_ips = [for vm in local.master_vms : vm.ip]
}
