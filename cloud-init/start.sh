#!/bin/bash

# Define the path to your inventory JSON file
inventory='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

# Check if the inventory file exists
check_inventory() {
    if [ ! -f "$inventory" ]; then
        echo "Inventory file not found at $inventory"
        exit 1
    fi
}

# Function to start a VM on a specific host
start_vm() {
    local vm_id=$1
    local target_ip=$2
    echo "Starting VM ID $vm_id on $target_ip..."
    ssh -i "${SSH_KEY}.pub" "$USER@$target_ip" "qm start $vm_id;"
}

# Ensure the inventory file exists
check_inventory

# Load VM IDs and their corresponding IPs from the JSON inventory using jq
mapfile -t vm_data < <(jq -r '.nodes[] | .ip as $ip | .vms[] | "\($ip) \(.id)"' $inventory)

# Loop through VM data and start VMs
for entry in "${vm_data[@]}"; do
    # Split entry into IP and VM ID
    ip=$(echo $entry | cut -d' ' -f1)
    vm_id=$(echo $entry | cut -d' ' -f2)

    # Start the VM
    start_vm $vm_id $ip
done

echo "All VMs have been started."
