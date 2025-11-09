terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }

  # Uncomment to enable remote state (recommended for team environments)
  # backend "s3" {
  #   bucket = "terraform-state"
  #   key    = "proxmox/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
