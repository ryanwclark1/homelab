resource "proxmox_vm_qemu" "vm" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid
  clone       = var.clone_template
  full_clone  = true

  # VM Settings
  agent       = 1
  cores       = var.cores
  sockets     = var.sockets
  memory      = var.memory
  onboot      = var.start_on_boot
  oncreate    = var.start_on_create
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-pci"

  # BIOS Settings
  bios    = "ovmf"
  machine = "q35"

  # EFI Disk
  efidisk {
    efitype = "4m"
    storage = var.storage
  }

  # OS Disk
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.storage
          ssd     = true
        }
      }
      # Additional storage disk for storage nodes
      dynamic "scsi1" {
        for_each = var.storage_disk_size != null ? [1] : []
        content {
          disk {
            size    = var.storage_disk_size
            storage = var.storage
            ssd     = true
          }
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-Init
  ipconfig0  = "ip=${var.ip_address},gw=${var.gateway}"
  nameserver = var.nameserver
  searchdomain = var.searchdomain
  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = var.ci_ssh_public_key

  # Serial Console
  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  # Tags
  tags = join(",", concat(var.tags, [var.role]))

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      cipassword, # Ignore password changes after creation
    ]
  }
}
