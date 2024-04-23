#!/bin/bash

# Associative array of hosts and corresponding VM IDs
declare -A vms_to_delete=(
    [andrew]="222 225 228"
    [john]="223 226 229"
    [peter]="224 227 230"
)

# Function to delete a VM on a specific host
delete_vm() {
    local vm_id=$1
    local target=$2
    echo "Deleting VM ID $vm_id on $target..."
    ssh root@"$target.techcasa.io" "qm stop $vm_id; qm destroy $vm_id"
}

# Loop through each host and their corresponding VM IDs
for target in "${!vms_to_delete[@]}"; do
    for vm_id in ${vms_to_delete[$target]}; do
        delete_vm $vm_id $target
    done
done
