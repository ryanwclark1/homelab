# Cloud-Init Template Creation
# This creates a reusable template for deploying K3s VMs

locals {
  cloud_image_filename = basename(var.cloud_image_url)
  cloud_image_path     = "/var/lib/vz/template/iso/${local.cloud_image_filename}"
}

# Download cloud image to Proxmox node
resource "null_resource" "download_cloud_image" {
  triggers = {
    image_url = var.cloud_image_url
    node      = var.template_node
  }

  # Download the cloud image if it doesn't exist
  provisioner "local-exec" {
    command = <<-EOT
      ssh root@${var.template_node}.techcasa.io "
        if [ ! -f ${local.cloud_image_path} ]; then
          echo 'Downloading cloud image...'
          cd /var/lib/vz/template/iso/
          wget -q --show-progress ${var.cloud_image_url}
          wget -q ${var.cloud_image_checksum_url}

          # Verify checksum
          sha512sum -c SHA512SUMS --ignore-missing

          if [ \$? -eq 0 ]; then
            echo 'Cloud image downloaded and verified successfully'
          else
            echo 'Checksum verification failed!'
            rm -f ${local.cloud_image_filename}
            exit 1
          fi
        else
          echo 'Cloud image already exists'
        fi
      "
    EOT
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Note: Cloud image not deleted. Remove manually if needed from ${self.triggers.node}'"
  }
}

# Create the cloud-init template VM
resource "proxmox_vm_qemu" "template" {
  depends_on = [null_resource.download_cloud_image]

  # Basic settings
  name        = var.template_name
  target_node = var.template_node
  vmid        = var.template_id

  # Make it a template
  template = true

  # VM configuration
  agent   = 1
  cores   = var.template_cores
  sockets = 1
  memory  = var.template_memory

  # BIOS settings
  bios    = "ovmf"
  machine = "q35"
  scsihw  = "virtio-scsi-pci"

  # EFI disk
  efidisk {
    efitype = "4m"
    storage = var.template_storage
  }

  # Boot configuration
  boot = "order=scsi0"

  # Disks - import the cloud image
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.template_disk_size
          storage = var.template_storage
          ssd     = true
          # Import from downloaded cloud image
          import_from = local.cloud_image_path
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.template_storage
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Serial console
  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  # Cloud-init defaults (can be overridden when cloning)
  ipconfig0 = "ip=dhcp"
  ciuser    = var.ci_user
  sshkeys   = var.ci_ssh_public_key

  # Lifecycle - template shouldn't be modified once created
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      network,
      ipconfig0,
      ciuser,
      sshkeys,
    ]
  }
}
