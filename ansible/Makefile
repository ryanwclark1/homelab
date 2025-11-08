.PHONY: help ping check lint site update backup health inventory install-collections

# Default target
help:
	@echo "Ansible Homelab Management"
	@echo ""
	@echo "Setup:"
	@echo "  install-collections  - Install required Ansible Galaxy collections"
	@echo ""
	@echo "Proxmox Operations:"
	@echo "  ping       - Test connectivity to all Proxmox hosts"
	@echo "  check      - Syntax check all playbooks"
	@echo "  lint       - Lint all Ansible files (requires ansible-lint)"
	@echo "  site       - Run full site configuration"
	@echo "  update     - Update all Proxmox hosts (serial)"
	@echo "  backup     - Backup Proxmox configurations"
	@echo "  health     - Run cluster health check"
	@echo "  inventory  - Display inventory"
	@echo ""
	@echo "TrueNAS Operations:"
	@echo "  truenas-setup   - Configure TrueNAS servers"
	@echo "  truenas-health  - TrueNAS health check"
	@echo "  truenas-info    - Display TrueNAS system info"
	@echo ""
	@echo "K3s Operations:"
	@echo "  k3s-deploy      - Deploy K3s cluster"
	@echo "  k3s-health      - K3s cluster health check"
	@echo "  k3s-kubeconfig  - Get kubeconfig from cluster"
	@echo ""
	@echo "Node-specific operations:"
	@echo "  ping-node NODE=name    - Ping specific node"
	@echo "  update-node NODE=name  - Update specific node"
	@echo "  health-node NODE=name  - Health check specific node"
	@echo ""
	@echo "Examples:"
	@echo "  make install-collections"
	@echo "  make ping"
	@echo "  make update-node NODE=james"
	@echo "  make truenas-health"

# Test connectivity
ping:
	ansible proxmox_cluster -m ping

# Ping specific node
ping-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make ping-node NODE=james"
	@exit 1
endif
	ansible $(NODE) -m ping

# Syntax check playbooks
check:
	@echo "Checking playbooks..."
	@for playbook in playbooks/*.yml; do \
		echo "Checking $$playbook..."; \
		ansible-playbook --syntax-check $$playbook; \
	done
	@echo "All playbooks passed syntax check"

# Lint Ansible files
lint:
	ansible-lint playbooks/*.yml || true

# Run full site configuration
site:
	ansible-playbook playbooks/site.yml

# Run site for specific node
site-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make site-node NODE=james"
	@exit 1
endif
	ansible-playbook playbooks/site.yml --limit $(NODE)

# Update all hosts (one at a time)
update:
	@echo "⚠️  This will update all Proxmox hosts serially"
	@read -p "Continue? (y/N) " confirm; \
	if [ "$$confirm" = "y" ]; then \
		ansible-playbook playbooks/update.yml; \
	else \
		echo "Update cancelled"; \
	fi

# Update specific node
update-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make update-node NODE=james"
	@exit 1
endif
	ansible-playbook playbooks/update.yml --limit $(NODE)

# Backup configurations
backup:
	ansible-playbook playbooks/backup.yml

# Backup specific node
backup-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make backup-node NODE=james"
	@exit 1
endif
	ansible-playbook playbooks/backup.yml --limit $(NODE)

# Health check
health:
	ansible-playbook playbooks/health-check.yml

# Health check specific node
health-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make health-node NODE=james"
	@exit 1
endif
	ansible-playbook playbooks/health-check.yml --limit $(NODE)

# Display inventory
inventory:
	ansible-inventory --graph

# Display inventory for specific group
inventory-group:
ifndef GROUP
	@echo "Error: GROUP parameter required. Usage: make inventory-group GROUP=proxmox_cluster"
	@exit 1
endif
	ansible-inventory --graph $(GROUP)

# List all hosts
hosts:
	ansible proxmox_cluster --list-hosts

# Gather facts
facts:
	ansible proxmox_cluster -m setup

# Facts for specific node
facts-node:
ifndef NODE
	@echo "Error: NODE parameter required. Usage: make facts-node NODE=james"
	@exit 1
endif
	ansible $(NODE) -m setup

# Run ad-hoc command
cmd:
ifndef CMD
	@echo "Error: CMD parameter required. Usage: make cmd CMD='uptime'"
	@exit 1
endif
	ansible proxmox_cluster -a "$(CMD)"

# Run ad-hoc command on specific node
cmd-node:
ifndef NODE
	@echo "Error: NODE parameter required"
	@exit 1
endif
ifndef CMD
	@echo "Error: CMD parameter required"
	@exit 1
endif
	ansible $(NODE) -a "$(CMD)"

# Quick setup workflow
setup: check ping health

# Complete deployment
deploy: check ping site health

# Maintenance workflow
maintain: backup update health

# Install Ansible Galaxy collections
install-collections:
	ansible-galaxy collection install -r requirements.yml --force

# Install collections if missing
check-collections:
	@ansible-galaxy collection list | grep -q community.proxmox || make install-collections
	@ansible-galaxy collection list | grep -q arensb.truenas || make install-collections

# TrueNAS operations
truenas-setup: check-collections
	ansible-playbook playbooks/truenas-setup.yml

truenas-health: check-collections
	ansible-playbook playbooks/truenas-health.yml

truenas-info:
	ansible truenas_servers -m uri -a "url={{ truenas_api_url }}/system/info method=GET headers='Authorization:Bearer {{ truenas_api_key }}' validate_certs=no" -c local

# K3s operations
k3s-deploy: check-collections
	ansible-playbook -i inventories/k3s/hosts.yml playbooks/k3s-deploy.yml

k3s-health:
	ansible-playbook -i inventories/k3s/hosts.yml playbooks/k3s-health.yml

k3s-kubeconfig:
	@echo "Fetching kubeconfig from k3s-node01..."
	@ansible k3s-node01 -i inventories/k3s/hosts.yml -m fetch -a "src=/etc/rancher/k3s/k3s.yaml dest=./kubeconfig.yaml flat=yes" -b
	@sed -i 's/127.0.0.1/10.10.101.50/g' kubeconfig.yaml
	@echo "Kubeconfig saved to ./kubeconfig.yaml"
	@echo "Use with: export KUBECONFIG=\$$(pwd)/kubeconfig.yaml"
