#!/bin/bash

# Define the path to your inventory JSON file
INVENTORY='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

# Check if the inventory file exists
check_inventory() {
  if [ ! -f "$INVENTORY" ]; then
    echo "Inventory file not found at $INVENTORY"
    exit 1
  fi
}

# Log Function
log_action() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to delete a VM on a specific host
delete_vm() {
  local vm_id=$1
  local target_ip=$2
  log_action "Deleting VM ID $vm_id on $target_ip"
  ssh "$USER@$target_ip" "qm stop $vm_id; qm destroy $vm_id"
}

# Ensure the inventory file exists
check_inventory

# Load VM IDs and their corresponding IPs from the JSON inventory using jq
mapfile -t vm_data < <(jq -r '.nodes[] | .ip as $ip | .vms[] | "\($ip) \(.id)"' $INVENTORY)

# Loop through VM data and delete VMs
for entry in "${vm_data[@]}"; do (
  # Split entry into IP and VM ID
  ip=$(echo $entry | cut -d' ' -f1)
  vm_id=$(echo $entry | cut -d' ' -f2)

  # Delete the VM and log the action
  delete_vm $vm_id $ip
  log_action "Deleted VM ID $vm_id on $target_ip"
) &
done
wait

# TODO: Add user input to confirm
source ../kubernetes/k3s/remove.sh

echo "All specified VMs have been processed for deletion."
