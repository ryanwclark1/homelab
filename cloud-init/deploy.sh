#!/bin/bash

# Define the path to your inventory JSON file
INVENTORY='../inventory.json'

BASE_VM=5001

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"
SSH_KEY_TEXT=$(cat $SSH_KEY.pub)

TAG="k3s"
CIDR=23
GATEWAY="10.10.100.1"

# Function to check for jq and install if not present
ensure_jq_installed() {
    if ! command -v jq &> /dev/null; then
        log_action "jq is not installed. Attempting to install..."
        case $(uname -s) in
            Linux)
                distro=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
                case $distro in
                    debian|ubuntu) sudo apt-get update && sudo apt-get install -y jq ;;
                    centos|fedora|rocky) sudo yum install -y jq ;;
                    alpine) sudo apk add jq ;;
                    arch) sudo pacman -Sy jq ;;
                    *) log_action "Unsupported distribution: $distro" && exit 1 ;;
                esac
                ;;
            *)
                log_action "Unsupported OS" && exit 1 ;;
        esac
    fi
    log_action "jq is installed."
}

# Function to check if inventory file exists
ensure_inventory_exists() {
    if [ ! -f "$INVENTORY" ]; then
        log_action "Inventory file not found at $INVENTORY"
        exit 1
    fi
}

# Log Function
log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Clone and configure VMs
clone_vm() {
    log_action "Cloning VM for $vm_name on $node_name ($node_ip) with ID $vm_id..."
    ssh "$USER@$template_ip" "
        qm clone $BASE_VM $vm_id \
        --name $vm_name \
        --full true \
        --target $node_name \
        --storage init
        exit
    "
}

# Initialize by checking inventory and jq
ensure_jq_installed
ensure_inventory_exists


# Load template node from inventory
template_node=$(jq -r '.template_node' $INVENTORY)
template_ip=$(jq -r '.nodes[] | select(.name == "'$template_node'") | .ip' $INVENTORY)



# Loop through VM data and deploy VMs
mapfile -t nodes < <(jq -c '.nodes[]' $INVENTORY)
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
        role=$(echo "$vm" | jq -r '.role')

        # clone_vm

        log_action "Configuring VM on $node_ip..."
        ssh "$USER@$node_ip" "
            qm set $vm_id --ipconfig0 ip=$vm_ip/$CIDR,gw=$GATEWAY;
            qm set $vm_id --tags "$TAG,$role";
            qm move-disk $vm_id scsi0 $disk;
            qm disk resize $vm_id scsi0 $disk_size;
            'TEMP_FILE="/tmp/key_temp.txt"';
            'touch "${TEMP_FILE}"';
            'echo $SSH_KEY_TEXT > "${TEMP_FILE}"';
            'cat ~/.ssh/id_rsa.pub >> "${TEMP_FILE}"';
            qm set $vm_id --sshkey "${TEMP_FILE}";
            rm "${TEMP_FILE}"
        "
        log_action "VM $vm_name ($vm_id) deployed and configured at $vm_ip."
    done
done

log_action "Deployment complete."