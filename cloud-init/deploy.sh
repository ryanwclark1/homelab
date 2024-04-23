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

# Log Function
log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if VM already exists
vm_exists() {
    local vm_id=$1
    local node_ip=$2
    # Execute qm status and capture output and exit status
    local output=$(ssh -i "$SSH_KEY" "$USER@$node_ip" "qm status $vm_id" 2>&1)
    local status=$?

    # Log the output and status for debugging
    echo "Output of qm status: $output"
    echo "Exit status: $status"

    # Check the status and specific output to determine if VM exists
    if [[ $status -eq 2 ]] || [[ $output =~ "does not exist" ]] || [[ $output =~ "Configuration file .* does not exist" ]]; then
        echo "VM does not exist: $output"
        return 1  # VM does not exist
    fi

    # Assume VM exists if no known error messages are found
    echo "VM exists."
    return 0
}

# Function to clone and configure VM
deploy_vm() {
    local node_ip=$1
    local node_name=$2
    local vm_id=$3
    local vm_name=$5
    local vm_ip=$6
    local disk=$7
    local disk_size=$8

    # Check if VM already exists
    if vm_exists $vm_id $node_ip; then
        log_action "VM $vm_name ($vm_id) already exists on $node_name ($node_ip), skipping clone."
    else
        log_action "Cloning VM for $vm_name on $node_name ($node_ip) with ID $vm_id..."
        ssh -i "$SSH_KEY" "$USER@$template_ip" "
            qm clone $base_vm $vm_id \
            --name $vm_name \
            --full true \
            --target $node_name \
            --storage init
            exit
        "
    fi

    log_action "Configuring VM on $node_name ($node_ip)..."
    echo $vm_ip
    ssh -i "$SSH_KEY" "$USER@$node_ip" "
            qm set $vm_id --ipconfig0 ip=$vm_ip/23,gw=10.10.100.1;
            qm move-disk $vm_id scsi0 $disk;
            qm disk resize $vm_id scsi0 $disk_size;
            exit
        "
    log_action "VM $vm_name ($vm_id) deployed and configured at $vm_ip."
}

# Initialize by checking inventory and jq
ensure_jq_installed
ensure_inventory_exists


mapfile -t nodes < <(jq -c '.nodes[]' $inventory)
for node in "${nodes[@]}"; do
    node_ip=$(echo "$node" | jq -r '.ip')
    node_name=$(echo "$node" | jq -r '.name')
    mapfile -t vms < <(echo "$node" | jq -c '.vms[]')
    for vm in "${vms[@]}"; do
        vm_id=$(echo "$vm" | jq -r '.id')
        vm_name=$(echo "$vm" | jq -r '.name')
        vm_ip=$(echo "$vm" | jq -r '.ip')
        disk=$(echo "$vm" | jq -r '.disk')
        disk_size=$(echo "$vm" | jq -r '.disk_size')

        deploy_vm "$node_ip" "$node_name" "$vm_id" "$vm_name" "$vm_ip" "$disk" "$disk_size"
    done
done

log_action "Deployment complete."