#!/bin/bash

# Define the path to your inventory JSON file
inventory='../inventory.json'

BASE_VM=5001
# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"
SSH_KEY_TEXT=$(cat $SSH_KEY.pub)
TAG="k3s"
CIDR=23
GATEWAY="10.10.100.1"

# Define the user for the SSH connections
prox_user=$(jq -r '.prox_user' "$inventory")
template_node=$(jq -r '.template_node' $inventory)
template_ip=$(jq -r '.nodes[] | select(.name == "'$template_node'") | .ip' $inventory)

# Function to check if inventory file exists
ensure_inventory_exists() {
  if [ ! -f "$inventory" ]; then
    log_action "Inventory file not found at $inventory"
    exit 1
  fi
}

# Log Function
log_action() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1 "
}

# Clone and configure VMs
clone_vm() {
  ssh "$prox_user@$template_ip" "
    qm clone $BASE_VM $vm_id \
    --name $vm_name \
    --full true \
    --target $node_name \
    --storage init
    exit
  " > /dev/null
}

ask_to_intialize() {
  while true; do
      # Prompt the user. The colon after the question suggests a default value of 'yes'
      echo -n "Do you want to run intialize the environment? [Y/n]: "
      read -r user_input

      # Default to 'yes' if the input is empty
      if [[ -z "$user_input" ]]; then
        user_input="yes"
      fi

      # Convert to lowercase to simplify the comparison
      user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

      case "$user_input" in
        y|yes)
          source ./intialize.sh > /dev/null
          echo "Environment intialized."
          break
          ;;
        n|no)
          echo "Environment will not be intialized"
          break
          ;;
        *)
          echo "Invalid input, please type 'Y' for yes or 'n' for no."
          ask_to_intialize
          ;;
      esac
  done
}

ask_to_start_vm() {
  while true; do
      # Prompt the user. The colon after the question suggests a default value of 'yes'
      echo -n "Do you want to start the VMs? [Y/n]: "
      read -r user_input
      # Default to 'yes' if the input is empty
      if [[ -z "$user_input" ]]; then
        user_input="yes"
      fi
      user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
      case "$user_input" in
        y|yes)
          source ./start.sh
          break
          ;;
        n|no)
          echo "Function will not run."
          break
          ;;
        *)
          echo "Invalid input, please type 'Y' for yes or 'n' for no."
          ask_to_start_vm
          ;;
      esac
  done
}

deploy_vm () {
  ssh "$prox_user@$node_ip" bash <<EOF
  qm set $vm_id --ipconfig0 ip=$vm_ip/$CIDR,gw=$GATEWAY;
  qm set $vm_id --tags "$TAG,$role";
  qm set $vm_id --cores "$cores" --sockets "$sockets" --memory "$memory";
  qm disk move $vm_id scsi0 $disk --delete 1;
  qm disk resize $vm_id scsi0 $disk_size;
  if [ -n "$storage_disk_size" ] && [ "$storage_disk_size" != "null" ]; then
    echo $storage_disk_size;
    storage_disk_size=\$(echo $storage_disk_size | tr -d '[:alpha:]);
    echo $storage_disk_size;
    qm set $vm_id --scsi1 $disk:$storage_disk_size,ssd=1;
  fi
  temp_file=\$(mktemp -t tmp_key.XXX);
  echo $SSH_KEY_TEXT > \$temp_file;
  cat ~/.ssh/id_rsa.pub >> \$temp_file;
  qm set $vm_id --sshkey \$temp_file;
  rm \$temp_file;
  exit
EOF
}

ensure_inventory_exists
ask_to_intialize
# Initialize by checking inventory and jq
source ./ensure_jq_installed.sh

# Loop through VM data and deploy VMs
mapfile -t nodes < <(jq -c '.nodes[]' $inventory)

for node in "${nodes[@]}"; do
  node_ip=$(echo "$node" | jq -r '.ip')
  node_name=$(echo "$node" | jq -r '.name')
  mapfile -t vms < <(echo "$node" | jq -c '.vms[]')

  for vm in "${vms[@]}"; do
    unset storage_disk_size
    vm_id=$(echo "$vm" | jq -r '.id')
    vm_name=$(echo "$vm" | jq -r '.name')
    vm_ip=$(echo "$vm" | jq -r '.ip')
    disk=$(echo "$vm" | jq -r '.disk')
    disk_size=$(echo "$vm" | jq -r '.disk_size')
    cores=$(echo "$vm" | jq -r '.cores')
    sockets=$(echo "$vm" | jq -r '.sockets')
    memory=$(echo "$vm" | jq -r '.memory')
    role=$(echo "$vm" | jq -r '.role')
    storage_disk_size=$(echo "$vm" | jq -r '.storage_disk_size')
    log_action "Cloning VM for $vm_name on $node_name ($node_ip) with ID $vm_id..."
    clone_vm
    log_action "Configuring VM on $node_ip..."
    deploy_vm
    log_action "VM $vm_name ($vm_id) deployed and configured at $vm_ip."
  done
done


echo "All VMs deployed and configured."

ask_to_start_vm

log_action "🎉 Deployment complete 🎉"
