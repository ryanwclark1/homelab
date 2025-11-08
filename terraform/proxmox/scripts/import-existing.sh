#!/bin/bash
# Script to import existing Proxmox VMs into Terraform state
# This is useful if you have already created VMs manually and want to manage them with Terraform

set -e

echo "========================================="
echo "Import Existing Proxmox VMs to Terraform"
echo "========================================="
echo ""
echo "This script will import your existing VMs into Terraform state."
echo "Make sure you have already run 'terraform init' first."
echo ""

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

# VM definitions from locals.tf
declare -A VMS=(
    ["k3s-node01"]="james/qemu/221"
    ["k3s-node02"]="andrew/qemu/222"
    ["k3s-node03"]="john/qemu/223"
    ["k3s-node04"]="peter/qemu/224"
    ["k3s-node05"]="judas/qemu/225"
    ["k3s-node06"]="philip/qemu/226"
    ["k3s-node07"]="andrew/qemu/227"
    ["k3s-node08"]="andrew/qemu/228"
    ["k3s-node09"]="john/qemu/229"
    ["k3s-node10"]="john/qemu/230"
    ["k3s-node11"]="peter/qemu/231"
    ["k3s-node12"]="peter/qemu/232"
    ["k3s-node13"]="judas/qemu/233"
    ["k3s-node14"]="judas/qemu/234"
    ["k3s-storage17"]="andrew/qemu/237"
    ["k3s-storage18"]="john/qemu/238"
    ["k3s-storage19"]="peter/qemu/239"
)

echo "Found ${#VMS[@]} VMs to import"
echo ""
read -p "Do you want to import all VMs? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Import cancelled."
    exit 0
fi

echo ""
echo "Starting import..."
echo ""

SUCCESS=0
FAILED=0

for vm_name in "${!VMS[@]}"; do
    vm_id="${VMS[$vm_name]}"
    echo "Importing $vm_name (ID: $vm_id)..."

    if terraform import "module.k3s_vms[\"$vm_name\"].proxmox_vm_qemu.vm" "$vm_id"; then
        echo "✓ Successfully imported $vm_name"
        ((SUCCESS++))
    else
        echo "✗ Failed to import $vm_name"
        ((FAILED++))
    fi
    echo ""
done

echo "========================================="
echo "Import Summary"
echo "========================================="
echo "Successfully imported: $SUCCESS"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All VMs imported successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run 'terraform plan' to verify the state"
    echo "2. Run 'terraform apply' to manage your VMs with Terraform"
else
    echo "⚠ Some imports failed. Check the errors above."
    echo "You may need to adjust VM IDs or check Proxmox configuration."
fi
