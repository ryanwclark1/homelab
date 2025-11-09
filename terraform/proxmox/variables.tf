# Proxmox Connection Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., root@pam!terraform)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (set to true for self-signed certificates)"
  type        = bool
  default     = true
}

# Network Configuration
variable "gateway" {
  description = "Default gateway for VMs"
  type        = string
  default     = "10.10.100.1"
}

variable "nameserver" {
  description = "DNS nameserver for VMs"
  type        = string
  default     = "10.10.100.1"
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
  default     = "techcasa.io"
}

variable "cidr_mask" {
  description = "CIDR mask for VM network"
  type        = string
  default     = "23"
}

# Cloud-Init Configuration
variable "ci_user" {
  description = "Cloud-init default user"
  type        = string
  default     = "administrator"
}

variable "ci_password" {
  description = "Cloud-init default password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ci_ssh_public_key" {
  description = "SSH public key for cloud-init"
  type        = string
}

variable "ci_ssh_private_key" {
  description = "SSH private key path for provisioning"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Template Configuration
variable "template_name" {
  description = "Name of the cloud-init template to clone"
  type        = string
  default     = "debian-bookworm-cloudinit"
}

variable "template_id" {
  description = "ID of the cloud-init template"
  type        = number
  default     = 5001
}

# K3s Configuration
variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.28.8+k3s1"
}

variable "k3s_token" {
  description = "K3s cluster token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "k3s_vip" {
  description = "K3s VIP for master nodes (kube-vip)"
  type        = string
  default     = "10.10.101.50"
}

variable "k3s_lb_range" {
  description = "LoadBalancer IP range for MetalLB"
  type        = string
  default     = "10.10.101.60-10.10.101.100"
}

# Default VM Configuration
variable "default_cores" {
  description = "Default CPU cores per VM"
  type        = number
  default     = 4
}

variable "default_sockets" {
  description = "Default CPU sockets per VM"
  type        = number
  default     = 1
}

variable "default_memory" {
  description = "Default memory in MB"
  type        = number
  default     = 8192
}

variable "default_disk_size" {
  description = "Default disk size (e.g., 10G)"
  type        = string
  default     = "10G"
}

variable "default_storage" {
  description = "Default storage pool"
  type        = string
  default     = "tank"
}

# VM Inventory
variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    target_node      = string
    vmid             = number
    name             = string
    ip               = string
    cores            = optional(number)
    sockets          = optional(number)
    memory           = optional(number)
    disk_size        = optional(string)
    storage          = optional(string)
    storage_disk_size = optional(string) # For storage nodes
    role             = string # master, worker, storage
    tags             = optional(list(string), [])
  }))
  default = {}
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = list(string)
  default     = ["terraform", "k3s"]
}
