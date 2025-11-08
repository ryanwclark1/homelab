.PHONY: help init plan apply destroy validate fmt lint clean show output console

# Default target
help:
	@echo "Terraform Proxmox Management"
	@echo ""
	@echo "Available targets:"
	@echo "  init       - Initialize Terraform"
	@echo "  validate   - Validate Terraform configuration"
	@echo "  fmt        - Format Terraform files"
	@echo "  plan       - Show Terraform plan"
	@echo "  apply      - Apply Terraform changes"
	@echo "  destroy    - Destroy Terraform resources"
	@echo "  show       - Show current Terraform state"
	@echo "  output     - Show Terraform outputs"
	@echo "  console    - Open Terraform console"
	@echo "  clean      - Clean Terraform cache"
	@echo ""
	@echo "Targeted operations:"
	@echo "  plan-vm VM=name    - Plan changes for specific VM"
	@echo "  apply-vm VM=name   - Apply changes for specific VM"
	@echo "  destroy-vm VM=name - Destroy specific VM"
	@echo ""
	@echo "Examples:"
	@echo "  make plan"
	@echo "  make apply-vm VM=k3s-node01"
	@echo "  make output"

# Initialize Terraform
init:
	terraform init -upgrade

# Validate configuration
validate:
	terraform validate

# Format Terraform files
fmt:
	terraform fmt -recursive

# Show what will be created
plan:
	terraform plan

# Apply changes
apply:
	terraform apply

# Destroy all resources
destroy:
	terraform destroy

# Show current state
show:
	terraform show

# Show outputs
output:
	terraform output

# Open Terraform console
console:
	terraform console

# Clean Terraform cache
clean:
	rm -rf .terraform/
	rm -f .terraform.lock.hcl

# Plan specific VM
plan-vm:
ifndef VM
	@echo "Error: VM parameter required. Usage: make plan-vm VM=k3s-node01"
	@exit 1
endif
	terraform plan -target=module.k3s_vms[\"$(VM)\"]

# Apply changes to specific VM
apply-vm:
ifndef VM
	@echo "Error: VM parameter required. Usage: make apply-vm VM=k3s-node01"
	@exit 1
endif
	terraform apply -target=module.k3s_vms[\"$(VM)\"]

# Destroy specific VM
destroy-vm:
ifndef VM
	@echo "Error: VM parameter required. Usage: make destroy-vm VM=k3s-node01"
	@exit 1
endif
	terraform destroy -target=module.k3s_vms[\"$(VM)\"]

# Create ansible inventory
inventory:
	terraform output -raw ansible_inventory > ansible_inventory.ini
	@echo "Ansible inventory saved to ansible_inventory.ini"

# Show SSH commands
ssh-commands:
	@terraform output -json ssh_commands | jq -r 'to_entries[] | "\(.key): \(.value)"'

# Quick setup workflow
setup: init validate fmt plan

# Full deployment workflow
deploy: init validate plan apply inventory

# Show cluster info
cluster-info:
	@terraform output -json k3s_cluster_info | jq '.'
	@echo ""
	@echo "Master nodes:"
	@terraform output -json master_nodes | jq -r 'to_entries[] | "  \(.key): \(.value.ip)"'
	@echo ""
	@echo "Worker nodes:"
	@terraform output -json worker_nodes | jq -r 'to_entries[] | "  \(.key): \(.value.ip)"'
	@echo ""
	@echo "Storage nodes:"
	@terraform output -json storage_nodes | jq -r 'to_entries[] | "  \(.key): \(.value.ip)"'
