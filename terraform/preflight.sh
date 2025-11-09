#!/usr/bin/env bash
# Pre-flight checks before Terraform deployment
# Validates environment and prerequisites

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 is installed"
        return 0
    else
        log_error "$1 is not installed"
        return 1
    fi
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Terraform Pre-Flight Checks                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 1. Check required commands
log_info "Checking required commands..."
check_command terraform || echo "  Install: https://www.terraform.io/downloads"
check_command jq || echo "  Install: apt install jq"
check_command ssh || echo "  Install: apt install openssh-client"
echo ""

# 2. Check Terraform version
log_info "Checking Terraform version..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    REQUIRED_VERSION="1.5.0"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        log_success "Terraform $TF_VERSION (>= $REQUIRED_VERSION)"
    else
        log_error "Terraform $TF_VERSION is too old (need >= $REQUIRED_VERSION)"
    fi
else
    log_error "Terraform not found"
fi
echo ""

# 3. Check SSH connectivity to Proxmox nodes
log_info "Checking SSH connectivity to Proxmox hosts..."
PROXMOX_NODES=("james" "andrew" "john" "peter" "judas" "philip")
for node in "${PROXMOX_NODES[@]}"; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes root@${node}.techcasa.io "echo ok" &> /dev/null; then
        log_success "SSH to $node.techcasa.io: OK"
    else
        log_error "SSH to $node.techcasa.io: FAILED"
        echo "  Fix: ssh-copy-id root@${node}.techcasa.io"
    fi
done
echo ""

# 4. Check Terraform configuration files
log_info "Checking Terraform configuration..."
if [ -f "templates/terraform.tfvars" ]; then
    log_success "templates/terraform.tfvars exists"
else
    log_warning "templates/terraform.tfvars not found"
    echo "  Create: cp templates/terraform.tfvars.example templates/terraform.tfvars"
fi

if [ -f "proxmox/terraform.tfvars" ]; then
    log_success "proxmox/terraform.tfvars exists"
else
    log_warning "proxmox/terraform.tfvars not found"
    echo "  Create: cp proxmox/terraform.tfvars.example proxmox/terraform.tfvars"
fi
echo ""

# 5. Check for required variables in tfvars
log_info "Checking required variables..."
if [ -f "proxmox/terraform.tfvars" ]; then
    if grep -q "proxmox_api_token_secret = \"your-api-token-secret-here\"" proxmox/terraform.tfvars 2>/dev/null; then
        log_error "Proxmox API token not configured (still using placeholder)"
    else
        log_success "Proxmox API token appears configured"
    fi

    if grep -q "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-ssh-public-key-here" proxmox/terraform.tfvars 2>/dev/null; then
        log_error "SSH public key not configured (still using placeholder)"
    else
        log_success "SSH public key appears configured"
    fi
fi
echo ""

# 6. Check Proxmox API accessibility
log_info "Checking Proxmox API..."
PROXMOX_API="https://james.techcasa.io:8006/api2/json"
if curl -k -s -f "${PROXMOX_API}/version" &> /dev/null; then
    log_success "Proxmox API accessible at $PROXMOX_API"
else
    log_warning "Cannot reach Proxmox API at $PROXMOX_API"
    echo "  This may be normal if you're not on the local network"
fi
echo ""

# 7. Check storage availability on Proxmox
log_info "Checking Proxmox storage..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes root@james.techcasa.io "zpool list tank" &> /dev/null 2>&1; then
    STORAGE_INFO=$(ssh root@james.techcasa.io "zpool list tank -o name,size,alloc,free -H")
    log_success "ZFS pool 'tank' available"
    echo "  $STORAGE_INFO"
else
    log_warning "Cannot verify ZFS pool 'tank'"
fi
echo ""

# 8. Check network requirements
log_info "Checking network configuration..."
if ping -c 1 -W 2 10.10.100.1 &> /dev/null; then
    log_success "Gateway 10.10.100.1 is reachable"
else
    log_warning "Gateway 10.10.100.1 is not reachable"
    echo "  You may not be on the homelab network"
fi

# Check if VIP is in use
if ping -c 1 -W 2 10.10.101.50 &> /dev/null; then
    log_warning "K3s VIP 10.10.101.50 is already responding"
    echo "  This is OK if cluster is already deployed"
else
    log_success "K3s VIP 10.10.101.50 is available"
fi
echo ""

# 9. Check disk space for cloud images
log_info "Checking disk space on Proxmox for cloud images..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes root@james.techcasa.io "df -h /var/lib/vz" &> /dev/null 2>&1; then
    DISK_SPACE=$(ssh root@james.techcasa.io "df -h /var/lib/vz | tail -1 | awk '{print \$4}'")
    log_success "Available space on james:/var/lib/vz: $DISK_SPACE"
else
    log_warning "Cannot check disk space on james"
fi
echo ""

# 10. Check Terraform state
log_info "Checking Terraform state..."
cd templates 2>/dev/null || true
if [ -f ".terraform.lock.hcl" ]; then
    log_info "Templates: Terraform initialized"
else
    log_warning "Templates: Terraform not initialized (run 'make init')"
fi
cd ..

cd proxmox 2>/dev/null || true
if [ -f ".terraform.lock.hcl" ]; then
    log_info "Proxmox: Terraform initialized"
else
    log_warning "Proxmox: Terraform not initialized (run 'make init')"
fi
cd ..
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Summary                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Pre-flight checks passed!${NC}"
    echo ""
    echo "Ready to deploy:"
    echo "  cd terraform/templates && make deploy"
    echo "  cd ../proxmox && make deploy"
    exit 0
else
    echo -e "${RED}✗ Pre-flight checks failed!${NC}"
    echo ""
    echo "Fix the errors above before deploying."
    exit 1
fi
