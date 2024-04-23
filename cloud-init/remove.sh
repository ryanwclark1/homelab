#!/bin/bash

# Define the path to your inventory JSON file
inventory='../inventory.json'

# Ensure the inventory file exists
check_inventory() {
    if [ ! -f "$inventory" ]; then
        echo "Inventory file not found at $inventory"
        exit 1
    fi
}

# Function to delete a VM on a specific host
delete_vm() {
    local vm_id=$1
    local target_dns=$2
    echo "Deleting VM ID $vm_id on $target_dns..."
    ssh root@"$target_dns" "qm stop $vm_id; qm destroy $vm_id"
}

# Function to log summary of actions
log_action() {
    local vm_id=$1
    local action=$2
    local target_dns=$3
    echo "$action VM ID $vm_id on $target_dns"
}

# Ensure the inventory file exists
check_inventory

# Load VM IDs and their corresponding DNS from the JSON inventory using jq
mapfile -t vm_data < <(jq -r '.nodes[] | .dns as $dns | .vms[] | "\($dns) \(.id)"' $inventory)

# Loop through VM data and delete VMs
for entry in "${vm_data[@]}"; do
    # Split entry into DNS and VM ID
    dns=$(echo $entry | cut -d' ' -f1)
    vm_id=$(echo $entry | cut -d' ' -f2)

    # Delete the VM and log the action
    delete_vm $vm_id $dns
    log_action $vm_id "Deleted" $dns
done

echo "All specified VMs have been processed for deletion."
