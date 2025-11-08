#!/bin/bash
# Complete Terraform deployment workflow
# This script orchestrates template creation and VM deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
PROXMOX_DIR="$SCRIPT_DIR/proxmox"

# Functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install Terraform >= 1.5.0"
        exit 1
    fi
    log_success "Terraform found: $(terraform version -json | jq -r '.terraform_version')"

    # Check jq
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found. Some features may not work. Install with: apt install jq"
    fi

    # Check SSH connectivity to template node
    log_info "Checking SSH connectivity to Proxmox..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes root@james.techcasa.io "echo 'SSH OK'" &> /dev/null; then
        log_success "SSH connectivity to james.techcasa.io verified"
    else
        log_error "Cannot connect to james.techcasa.io via SSH"
        log_info "Setup SSH key-based auth: ssh-copy-id root@james.techcasa.io"
        exit 1
    fi

    # Check terraform.tfvars
    if [ ! -f "$TEMPLATES_DIR/terraform.tfvars" ]; then
        log_error "Template configuration missing: $TEMPLATES_DIR/terraform.tfvars"
        log_info "Copy and edit: cp $TEMPLATES_DIR/terraform.tfvars.example $TEMPLATES_DIR/terraform.tfvars"
        exit 1
    fi

    if [ ! -f "$PROXMOX_DIR/terraform.tfvars" ]; then
        log_error "Proxmox configuration missing: $PROXMOX_DIR/terraform.tfvars"
        log_info "Copy and edit: cp $PROXMOX_DIR/terraform.tfvars.example $PROXMOX_DIR/terraform.tfvars"
        exit 1
    fi

    log_success "All prerequisites met"
    echo ""
}

create_template() {
    log_info "Step 1/2: Creating cloud-init template..."
    echo ""

    cd "$TEMPLATES_DIR"

    # Check if template already exists
    if terraform state list 2>/dev/null | grep -q "proxmox_vm_qemu.template"; then
        log_warning "Template already exists in Terraform state"
        read -p "Do you want to recreate it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Recreating template..."
            make destroy
            make init
            make apply
        else
            log_info "Skipping template creation"
        fi
    else
        # Initialize and create
        make init
        make apply
    fi

    # Verify template creation
    if terraform state list | grep -q "proxmox_vm_qemu.template"; then
        log_success "Cloud-init template created successfully"
        make info
    else
        log_error "Template creation failed"
        exit 1
    fi

    echo ""
    cd "$SCRIPT_DIR"
}

deploy_vms() {
    log_info "Step 2/2: Deploying K3s VMs..."
    echo ""

    cd "$PROXMOX_DIR"

    # Initialize
    make init

    # Show plan
    log_info "Terraform plan:"
    make plan

    echo ""
    read -p "Do you want to apply these changes? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled"
        exit 0
    fi

    # Apply
    make apply

    # Generate inventory
    log_info "Generating Ansible inventory..."
    make inventory

    log_success "VM deployment complete"
    echo ""

    # Show cluster info
    make cluster-info

    cd "$SCRIPT_DIR"
}

show_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                   Deployment Summary                           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Cloud-init template: james:5001 (debian-bookworm-cloudinit)"
    log_success "K3s VMs: 14 VMs (6 masters, 5 workers, 3 storage)"
    log_success "Ansible inventory: $PROXMOX_DIR/ansible_inventory.ini"
    echo ""
    echo "Next steps:"
    echo "  1. Verify VMs: cd $PROXMOX_DIR && make cluster-info"
    echo "  2. SSH to a node: ssh administrator@10.10.101.221"
    echo "  3. Deploy K3s: Use Ansible with generated inventory"
    echo ""
    log_info "To view SSH commands: cd $PROXMOX_DIR && make ssh-commands"
    echo ""
}

# Main workflow
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Homelab Infrastructure Deployment                      ║"
    echo "║         Terraform + Proxmox + Cloud-Init                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Parse arguments
    case "${1:-all}" in
        template)
            check_prerequisites
            create_template
            ;;
        vms)
            check_prerequisites
            deploy_vms
            show_summary
            ;;
        all)
            check_prerequisites
            create_template
            deploy_vms
            show_summary
            ;;
        check)
            check_prerequisites
            ;;
        *)
            echo "Usage: $0 [all|template|vms|check]"
            echo ""
            echo "Commands:"
            echo "  all      - Complete deployment (template + VMs)"
            echo "  template - Create cloud-init template only"
            echo "  vms      - Deploy VMs only (requires template)"
            echo "  check    - Check prerequisites"
            echo ""
            echo "Examples:"
            echo "  $0              # Deploy everything"
            echo "  $0 template     # Create template only"
            echo "  $0 vms          # Deploy VMs only"
            echo "  $0 check        # Check prerequisites"
            exit 1
            ;;
    esac
}

main "$@"
