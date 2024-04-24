#!/bin/bash

# Path to your inventory JSON file
INVENTORY='../inventory.json'

# Define the user for the SSH connections
USER=root

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

# Function to check and install jq if not present
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

# Ensure jq is installed
ensure_jq_installed

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
