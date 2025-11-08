.PHONY: help init plan apply destroy validate fmt show output

# Default target
help:
	@echo "Cloud-Init Template Management"
	@echo ""
	@echo "Available targets:"
	@echo "  init       - Initialize Terraform"
	@echo "  validate   - Validate Terraform configuration"
	@echo "  fmt        - Format Terraform files"
	@echo "  plan       - Show Terraform plan"
	@echo "  apply      - Create cloud-init template"
	@echo "  destroy    - Destroy template (use with caution!)"
	@echo "  show       - Show current Terraform state"
	@echo "  output     - Show Terraform outputs"
	@echo "  info       - Show template information"
	@echo "  recreate   - Destroy and recreate template"
	@echo ""
	@echo "Examples:"
	@echo "  make init"
	@echo "  make apply"
	@echo "  make info"

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

# Create template
apply:
	@echo "⚠️  This will create the cloud-init template on Proxmox"
	@echo "    Template ID: 5001"
	@echo "    Node: james"
	@echo ""
	terraform apply

# Destroy template
destroy:
	@echo "⚠️  WARNING: This will destroy the cloud-init template!"
	@echo "    All VMs cloned from this template may be affected."
	@echo ""
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform destroy; \
	else \
		echo "Destroy cancelled."; \
	fi

# Show current state
show:
	terraform show

# Show outputs
output:
	terraform output

# Show template info
info:
	@echo "Cloud-Init Template Information"
	@echo "================================"
	@terraform output -json template_info | jq -r '"Template ID: \(.id)\nTemplate Name: \(.name)\nNode: \(.node)"'
	@echo ""
	@terraform output -raw cloud_image_path | xargs -I {} echo "Cloud image: {}"

# Recreate template (destroy and create)
recreate: destroy apply

# Setup workflow
setup: init validate fmt plan

# Quick deploy
deploy: init validate apply info
