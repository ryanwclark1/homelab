#!/bin/bash

# Set the user
CURRENT_USER=$(whoami)

# Remove the export statement from the appropriate shell configuration file
remove_export_statement() {
  local file="$1"
  local pattern="export KUBECONFIG=/home/${CURRENT_USER}/.kube/config"
  # Use printf to safely escape the path for use in a regular expression
  local escaped_pattern=$(printf '%s\n' "$pattern" | sed -e 's:[][\/.^$*]:\\&:g')

  echo "Checking for the export statement in ${file}"
  if grep -Fq "$pattern" "$file"; then
    echo "Removing export statement from ${file}"
    # Use the escaped pattern with sed and create a backup for safety
    sed -i.bak "/$escaped_pattern/d" "$file"
    echo "Backup of original file created as ${file}.bak"
  else
    echo "No export statement found in ${file}. Skipping..."
  fi
}

# Determine the shell and the corresponding configuration file
SHELL_NAME=$(basename "$SHELL")

case "$SHELL_NAME" in
  "bash")
    CONFIG_FILE="/home/$CURRENT_USER/.bashrc"
    ;;
  "zsh")
    CONFIG_FILE="/home/$CURRENT_USER/.zshrc"
    ;;
  "fish")
    CONFIG_FILE="/home/$CURRENT_USER/.config/fish/config.fish"
    ;;
  *)
    echo "Unknown shell: $SHELL_NAME"
    exit 1
    ;;
esac

# Remove the export statement from the configuration file
remove_export_statement "$CONFIG_FILE"


# Function to safely remove files or directories
safe_rm() {
  local target="$1"
  if [ -e "$target" ]; then
    # Try to remove normally
    rm -rf "$target" 2>/dev/null
    if [ $? -ne 0 ]; then
      # If the removal failed, try it with sudo
      echo "Normal removal failed for ${target}, attempting with sudo..."
      sudo rm -rf "$target"
      if [ $? -ne 0 ]; then
        echo "Failed to remove ${target} with sudo."
      else
        echo "Removed ${target} using sudo."
      fi
    else
      echo "Removed ${target}"
    fi
  else
    echo "Target ${target} not found. Skipping..."
  fi
}


# Remove the kubeconfig file and directory
safe_rm "/usr/local/helm"
safe_rm "/home/$CURRENT_USER/.config/helm"
safe_rm "/home/$CURRENT_USER/.cache/helm"
safe_rm "/home/$CURRENT_USER/.kube/config"
safe_rm "/home/$CURRENT_USER/kube-vip.yaml"
safe_rm "/home/$CURRENT_USER/ipAddressPool.yaml"
safe_rm "/usr/local/bin/kubectl"
safe_rm "/usr/local/bin/k3sup"


# If it's a master node, kill k3s
if [ -f "/etc/rancher/k3s.yaml" ]; then
  k3s-killall
  k3s-agent-uninstall.sh
else
  echo "This is not a master node."
fi

echo "Clearing known hosts..."
> ~/.ssh/known_hosts


echo "Removal completed successfully."
