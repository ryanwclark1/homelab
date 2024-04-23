#!/bin/bash

# Path to your inventory JSON file
inventory='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

# Function to check and install jq if not present
ensure_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq
        if ! command -v jq &> /dev/null; then
            echo "Failed to install jq. Exiting script."
            exit 1
        fi
    fi
    echo "jq is installed."
}

# Ensure jq is installed
ensure_jq_installed

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY" -N ""
    echo "SSH key generated."
else
    echo "SSH key already exists."
fi

# Extract hosts from the JSON inventory using jq
HOSTS=($(jq -r '.nodes[].ip' $inventory))

# Copy SSH public key to each host
for HOST in "${HOSTS[@]}"; do
    echo "Copying SSH public key to $HOST..."
    ssh-copy-id -i "${SSH_KEY}.pub" "$USER@$HOST"
done

echo "SSH setup complete."
