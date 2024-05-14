#!/bin/bash

#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################


# Define the path to your inventory JSON file
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

k3s_version=$(jq -r '.k3s_version' "$inventory")
master1_name=$(jq -r '.master1_name' "$inventory")
master1=$(jq -r --arg vm_name "$master1_name" '.nodes[].vms[] | select(.name == $vm_name) | .ip' "$inventory")
lbrange=$(jq -r '.lbrange' "$inventory")
host_user=$(jq -r '.host_user' "$inventory")
interface=$(jq -r '.interface' "$inventory")
vip=$(jq -r '.vip' "$inventory")
cert_name=$(jq -r '.cert_name' "$inventory")

mapfile -t masters < <(jq -r --arg ip "$master1" '.nodes[].vms[] | select(.role == "master" and .ip != $ip) | .ip' "$inventory") # Arrays of masters ex master1
mapfile -t workers < <(jq -r '.nodes[].vms[] | select(.role != "master") | .ip' "$inventory") # Array of worker nodes
mapfile -t storage < <(jq -r '.nodes[].vms[] | select(.role == "storage") | .ip' "$inventory") # Array of storage nodes
mapfile -t all < <(jq -r '.nodes[].vms[].ip' "$inventory") # Array of all

SSH_KEY="$HOME/.ssh/$cert_name"
SHELL_NAME=$(basename "$SHELL")
CURRENT_USER=$(whoami)

#############################################
#            DO NOT EDIT BELOW              #
#############################################

initialize_nodes() {
  # Add ssh keys for all nodes
  for node in "${all[@]}"; do
    ssh-keyscan -H $node >> ~/.ssh/known_hosts
    ssh-copy-id $host_user@$node
    ssh $host_user@$node -i ~/.ssh/$cert_name sudo su <<EOF
    NEEDRESTART_MODE=a
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get install -yq policycoreutils open-iscsi nfs-common cryptsetup dmsetup jq
    exit
EOF

    # Check if the current node is in the storage array
    if [[ " ${storage[*]} " == *" $node "* ]]; then
        unset storage_disk_size
        storage_disk_size=$(jq -r --arg ip "$node" '.nodes[].vms[] | select(.ip == $ip) | .storage_disk_size' "$inventory")
        echo "Storage disk size: $storage_disk_size"

        ssh $host_user@$node -i ~/.ssh/$cert_name storage_disk_size=$storage_disk_size <<EOF
          sudo su
          echo "Storage disk size remote: $storage_disk_size"
          # Find the disk that matches the storage_disk_size
          BLK_ID=\$(lsblk --json | jq -r --arg size "$storage_disk_size" '.blockdevices[] | select(.size == $size and .type == "disk") | .name')
          BLK_ID="/dev/\$BLK_ID"
          MOUNT_POINT=/var/lib/longhorn
          echo 'label: gpt' | sudo sfdisk \$BLK_ID
          echo ',,L' | sudo sfdisk \$BLK_ID
          sudo mkfs.ext4 -F \${BLK_ID}1
          PART_UUID=\$(sudo blkid | grep \$BLK_ID | rev | cut -d ' ' -f -1 | tr -d '"' | rev)
          echo \$PART_UUID
          sudo mkdir -p \$MOUNT_POINT
          echo "\$PART_UUID \$MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab
          sudo systemctl daemon-reload
          sudo reboot
EOF
    fi
    echo -e " \033[32;5mNode: $node Initialized!\033[0m"
  done

  echo -e " \033[32;5mAll nodes initialized!\033[0m"
}



ask_to_intialize() {
  while true; do
      # Prompt the user. The colon after the question suggests a default value of 'yes'
      echo -n "Do you want to run intialize the environment? [Y/n]: "
      read -r user_input
      if [[ -z "$user_input" ]]; then
        user_input="yes"
      fi

      # Convert to lowercase to simplify the comparison
      user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

      case "$user_input" in
        y|yes)
          intialize_nodes
          break
          ;;
        n|no)
          echo "Function will not run."
          break
          ;;
        *)
          echo "Invalid input, please type 'Y' for yes or 'n' for no."
          ask_to_intialize
          ;;
      esac
  done
}

# ask_to_intialize
initialize_nodes