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

node=10.10.101.237
storage_disk_size=200G

#############################################
#            DO NOT EDIT BELOW              #
#############################################

ssh $host_user@$node -i ~/.ssh/$cert_name "storage_disk_size=$storage_disk_size sudo su -c '
  # Find the disk that matches the storage_disk_size
  BLK_ID=\$(lsblk --json | jq -r --arg size \"\$storage_disk_size\" \".blockdevices[] | select(.size == \$size and .type == \\\"disk\\\") | .name\")
  BLK_ID=\"/dev/\$BLK_ID\"
  if [ -n \"\$BLK_ID\" ]; then
    MOUNT_POINT=/var/lib/longhorn
    echo \"label: gpt\" | sudo sfdisk \$BLK_ID
    echo \",,L\" | sudo sfdisk \$BLK_ID
    sudo mkfs.ext4 -F \${BLK_ID}1
    PART_UUID=\$(sudo blkid | grep \$BLK_ID | rev | cut -d \" \" -f -1 | tr -d '\"' | rev)
    if [ -n \"\$PART_UUID\" ]; then
      echo \$PART_UUID
      sudo mkdir -p \$MOUNT_POINT
      echo \"\$PART_UUID \$MOUNT_POINT ext4 defaults 0 2\" | sudo tee -a /etc/fstab
      # sudo systemctl daemon-reload
      # sudo reboot
    else
      echo \"PART_UUID is null, not updating /etc/fstab\"
    fi
  else
    echo \"BLK_ID is null, not proceeding with disk setup\"
  fi
'"