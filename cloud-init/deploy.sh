#!/bin/bash

# Base VM ID for cloning
base_vm=5001

# Define the path to your inventory JSON file
inventory='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

vm_cidr=23
vm_gateway="10.10.100.1"

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
template_ip=$(jq -r '.nodes[] | select(.name == "'$template_node'") | .ip' $inventory)

# Log Function
log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Loop through VM data and deploy VMs
jq -c '.nodes[]' $inventory | while read -r node; do
    node_name=$(echo $node | jq -r '.name')
    node_ip=$(echo $node | jq -r '.ip')
    echo $node | jq -c '.vms[]' | while read -r vm; do
        vm_name=$(echo $vm | jq -r '.name')
        vm_ip=$(echo $vm | jq -r '.ip')
        disk=$(echo $vm | jq -r '.disk')
        disk_size=$(echo $vm | jq -r '.disk_size')
        vm_id=$(echo $vm | jq -r '.id')

        log_action "Cloning VM for $vm_name on $node_name ($node_ip) with ID $vm_id..."
        ssh "$USER@$template_ip" "
            qm clone 5001 $vm_id \
            --name $vm_name \
            --full true \
            --target $node_name \
            --storage init
            exit
        "

        log_action "Configuring VM on $node_ip..."
        ssh "$USER@$node_ip" "
            qm set $vm_id --ipconfig0 ip=$vm_ip/$vm_cidr,gw=$vm_gateway;
            qm move-disk $vm_id scsi0 $disk;
            qm disk resize $vm_id scsi0 $disk_size;
            exit
        "
        log_action "VM $vm_name ($vm_id) deployed and configured at $vm_ip."
    done
done

log_action "Deployment complete."
