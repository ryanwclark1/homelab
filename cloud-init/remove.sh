#!/bin/bash

# Associative array of hosts and corresponding VM IDs
declare -A vms_to_delete=(
    [james]="221"
    [andrew]="222 227 228"
    [john]="223 229 230"
    [peter]="224 231 232"
    [judas]="225 233 234"
    [philip]="226 235 236"
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
