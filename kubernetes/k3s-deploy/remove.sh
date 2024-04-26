#!/bin/bash

# Set the user
CURRENT_USER=$(whoami)

# Set the kubeconfig path
KUBECONFIG_PATH="/home/$CURRENT_USER/.kube"

# Remove the export statement from the appropriate shell configuration file
remove_export_statement() {
    local file="$1"
    local pattern="export KUBECONFIG=${KUBECONFIG_PATH}/config"
    echo "Checking for the export statement in ${file}"
    if grep -q "$pattern" "$file"; then
        echo "Removing export statement from ${file}"
        sed -i "/$pattern/d" "$file"
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
        rm -rf "$target"
        echo "Removed ${target}"
    else
        echo "Target ${target} not found. Skipping..."
    fi
}

# Remove the kubeconfig file and directory
safe_rm "$XDG_CACHE_HOME/helm"
safe_rm "$XDG_CONFIG_HOME/helm"
safe_rm "$XDG_DATA_HOME/helm"
safe_rm "$KUBECONFIG_PATH"
safe_rm "/usr/local/bin/kubectl"
safe_rm "/usr/local/bin/k3sup"
safe_rm "$HOME/kube-vip.yaml"
safe_rm "$HOME/ipAddressPool.yaml"

# If it's a master node, kill k3s
if [ -f "/etc/rancher/k3s.yaml" ]; then
    k3s-killall
    k3s-agent-uninstall.sh
else
    echo "This is not a master node."
fi

echo "Removal completed successfully."
