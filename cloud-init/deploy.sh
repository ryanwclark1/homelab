#!/bin/bash

# Base VM ID for cloning
base_vm=5001

# Define the path to your inventory JSON file
inventory='../inventory.json'

# Function to check for jq and install if not present
ensure_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Attempting to install..."
        case $(uname -s) in
            Linux)
                distro=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
                case $distro in
                    debian|ubuntu) sudo apt-get update && sudo apt-get install -y jq ;;
                    centos|fedora|rocky) sudo yum install -y jq ;;
                    alpine) sudo apk add jq ;;
                    arch) sudo pacman -Sy jq ;;
                    *) echo "Unsupported distribution: $distro" && exit 1 ;;
                esac
                ;;
            *)
                echo "Unsupported OS" && exit 1 ;;
        esac
    fi
    echo "jq is installed."
}

# Function to check if inventory file exists
ensure_inventory_exists() {
    if [ ! -f "$inventory" ]; then
        echo "Inventory file not found at $inventory"
        exit 1
    fi
}

# Initialize by checking inventory and jq
ensure_jq_installed
ensure_inventory_exists

# Load template node from inventory
template_node=$(jq -r '.template_node' $inventory)

# Start VM ID for clones (dynamic)
vm_id=$(jq -r '.nodes[].vms[].id' $inventory | sort -n | tail -n 1)
((vm_id++))

# Loop through VM data and deploy VMs
jq -c '.nodes[]' $inventory | while read -r node; do
    dns=$(echo $node | jq -r '.dns')
    echo $node | jq -c '.vms[]' | while read -r vm; do
        name=$(echo $vm | jq -r '.name')
        disk=$(echo $vm | jq -r '.disk')
        disk_size=$(echo $vm | jq -r '.disk_size')
        echo "Cloning VM for $name on $dns with ID $vm_id..."
        ssh root@"$template_node.techcasa.io" "
            qm clone $base_vm $vm_id \
            --name $name \
            --full true \
            --target $dns \
            --storage init
            exit
        "
        echo "Configuring VM on $dns..."
        ssh root@"$dns" "
            qm set $vm_id --ipconfig0 ip=10.10.101.$vm_id/23,gw=10.10.100.1;
            qm move-disk $vm_id scsi0 $disk;
            qm disk resize $vm_id scsi0 $disk_size;
            exit
        "
        ((vm_id++))
    done
done

echo "Deployment complete."
