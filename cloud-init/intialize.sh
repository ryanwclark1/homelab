#!/bin/bash

# Path to your inventory JSON file
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

# Define the user for the SSH connections
prox_user=($(jq -r '.prox_user' $inventory))
cert_name=$(jq -r '.cert_name' "$inventory")
hosts=($(jq -r '.nodes[].ip' $inventory))

SSH_KEY="$HOME/.ssh/$cert_name"


# Ensure jq is installed
source ../base/ensure_jq_installed.sh

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
  echo "Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -o -a 100 -f "$SSH_KEY" -N ""
  echo "SSH key generated."
else
  echo "SSH key already exists."
fi

# Extract hosts from the JSON inventory using jq


# Copy SSH public key to each host
for host in "${hosts[@]}"; do
  echo "Copying SSH public key to $host..."
  ssh-keyscan -H $host >> ~/.ssh/known_hosts
  ssh-copy-id -i "${SSH_KEY}" "$prox_user@$host"
done

echo "SSH setup complete."
