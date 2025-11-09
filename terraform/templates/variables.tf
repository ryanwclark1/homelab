# Variables for template creation

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "template_node" {
  description = "Proxmox node to create template on"
  type        = string
  default     = "james"
}

variable "template_id" {
  description = "VM ID for the template"
  type        = number
  default     = 5001
}

variable "template_name" {
  description = "Template name"
  type        = string
  default     = "debian-bookworm-cloudinit"
}

variable "template_storage" {
  description = "Storage pool for template"
  type        = string
  default     = "tank"
}

variable "cloud_image_url" {
  description = "URL to cloud image"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

variable "cloud_image_checksum_url" {
  description = "URL to checksum file"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS"
}

variable "ci_user" {
  description = "Default cloud-init user"
  type        = string
  default     = "administrator"
}

variable "ci_ssh_public_key" {
  description = "SSH public key for template"
  type        = string
}

variable "template_cores" {
  description = "Default CPU cores"
  type        = number
  default     = 2
}

variable "template_memory" {
  description = "Default memory in MB"
  type        = number
  default     = 4096
}

variable "template_disk_size" {
  description = "Default disk size"
  type        = string
  default     = "10G"
}
