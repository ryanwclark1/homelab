#!/bin/bash

template_node="james"

# List of VM IDs to start
vm_ids=(221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236)

# Function to start a VM
start_vm() {
    local vm_id=$1
    echo "Starting VM ID $vm_id..."
    ssh root@"$template_node.techcasa.io" "
      qm start $vm_id
      exit
    "
}

# Loop over all VM IDs and start each one
for vm_id in "${vm_ids[@]}"; do
    start_vm $vm_id
done

echo "All VMs have been started."