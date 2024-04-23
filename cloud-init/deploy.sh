#!/bin/bash

# Base VM ID for cloning
base_vm=5001

# Array of target hosts and corresponding node names
declare -A nodes=(
    [andrew]="k3s-node02 k3s-node05 k3s-node08"
    [john]="k3s-node03 k3s-node06 k3s-node09"
    [peter]="k3s-node04 k3s-node07 k3s-node10"
)

# Start VM ID for clones
vm_id=222

for target in "${!nodes[@]}"; do
    for node in ${nodes[$target]}; do
        echo "Cloning VM for $node on $target with ID $vm_id..."
        qm clone $base_vm $vm_id \
          --name $node \
          --full true \
          --target $target \
          --storage init

        echo "Configuring VM on $target..."
        ssh root@"$target.techcasa.io" "
            qm set $vm_id --ipconfig0 ip=10.10.101.$vm_id/23,gw=10.10.100.1;
            qm move-disk $vm_id scsi0 tank;
            qm disk resize $vm_id scsi0 10G;
            exit
        "

        # Increment VM ID for the next node
        ((vm_id++))
    done
done