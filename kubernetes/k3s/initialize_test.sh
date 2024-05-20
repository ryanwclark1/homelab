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
for node in "${all[@]}"; do
  # Check if the current node is in the storage array
  if [[ " ${storage[*]} " == *" $node "* ]]; then
    # unset storage_disk_size
    # storage_disk_size=$(jq -r --arg ip "$node" '.nodes[].vms[] | select(.ip == $ip) | .storage_disk_size' "$inventory")
    # echo "Storage disk size: $storage_disk_size"

    ssh "$host_user@$node" -i ~/.ssh/$cert_name <<'EOF'
    echo "Setting up storage node: $node"
    MOUNT_POINT="/var/lib/longhorn"
    echo "$MOUNT_POINT"
    if ! grep -q "$MOUNT_POINT" /etc/fstab; then

      BLK_ID=$(lsblk --json | jq -r '.blockdevices[]? | del(select(has("children"))) | select(.name != null and .type == "disk") | .name')
      if [ -n "$BLK_ID" ]; then
        BLK_ID_PATH="/dev/$BLK_ID"
        echo "$BLK_ID_PATH"
        echo 'label: gpt' | sudo sfdisk "$BLK_ID_PATH"
        echo ',,L' | sudo sfdisk "$BLK_ID_PATH"
        BLK_ID_CHILD=$(lsblk --json | jq -r --arg BLK_ID "$BLK_ID" '.blockdevices[]? | select(.name == $BLK_ID) | .children[0].name')
        echo "$BLK_ID_CHILD"
        BLK_ID_CHILD_PATH="/dev/$BLK_ID_CHILD"
        sudo mkfs.ext4 -F "$BLK_ID_CHILD_PATH"
        PART_UUID=$(lsblk -O --json | jq -r --arg BLK_ID_CHILD_PATH "$BLK_ID_CHILD_PATH" '.blockdevices[]?.children[]? | select(.path == $BLK_ID_CHILD_PATH) | .partuuid')
        if [ -n "$PART_UUID" ]; then
          echo "$PART_UUID"
          sudo mkdir -p "$MOUNT_POINT"
          if ! grep -q "$PART_UUID" /etc/fstab; then
            echo "PARTUUID=$PART_UUID $MOUNT_POINT ext4 defaults 0 0" | sudo tee -a /etc/fstab
          else
            echo 'UUID already in /etc/fstab'
          fi
          sudo mount -a
          sudo systemctl daemon-reload
          sudo findmnt --verify --verbose
          # sudo reboot
        else
          echo 'PART_UUID is null, not updating /etc/fstab'
        fi
      else
        echo 'BLK_ID is null, not proceeding with disk setup'
      fi
    else
      echo "MOUNT_POINT $MOUNT_POINT already in /etc/fstab"
    fi
EOF
    echo -e " \033[32;5mStorage Node: $node Initialized!\033[0m"
  fi
  echo -e " \033[32;5mNode: $node Initialized!\033[0m"
done

echo -e " \033[32;5mAll nodes initialized!\033[0m"