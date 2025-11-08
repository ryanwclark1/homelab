# Module variables for K3s VM
variable "target_node" {
  description = "Proxmox node to deploy to"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "name" {
  description = "VM name"
  type        = string
}

variable "clone_template" {
  description = "Template name to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "Disk size (e.g., 10G)"
  type        = string
  default     = "10G"
}

variable "storage" {
  description = "Storage pool name"
  type        = string
  default     = "tank"
}

variable "storage_disk_size" {
  description = "Additional storage disk size for storage nodes (optional)"
  type        = string
  default     = null
}

variable "ip_address" {
  description = "IP address in CIDR notation (e.g., 10.10.101.221/23)"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
}

variable "ci_user" {
  description = "Cloud-init user"
  type        = string
}

variable "ci_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
}

variable "ci_ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "role" {
  description = "K3s role (master, worker, storage)"
  type        = string
  validation {
    condition     = contains(["master", "worker", "storage"], var.role)
    error_message = "Role must be one of: master, worker, storage"
  }
}

variable "tags" {
  description = "VM tags"
  type        = list(string)
  default     = []
}

variable "start_on_create" {
  description = "Start VM on creation"
  type        = bool
  default     = false
}

variable "start_on_boot" {
  description = "Start VM on Proxmox boot"
  type        = bool
  default     = true
}
