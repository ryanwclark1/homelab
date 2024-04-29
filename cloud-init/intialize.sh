#!/bin/bash

# Path to your inventory JSON file
INVENTORY='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"


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
HOSTS=($(jq -r '.nodes[].ip' $INVENTORY))

# Copy SSH public key to each host
for HOST in "${HOSTS[@]}"; do
  echo "Copying SSH public key to $HOST..."
  ssh-keyscan -H $HOST >> ~/.ssh/known_hosts
  ssh-copy-id -i "${SSH_KEY}" "$USER@$HOST"
done

echo "SSH setup complete."
