#!/bin/bash

# Set the user
CURRENT_USER=$(whoami)

# Set the kubeconfig path
KUBECONFIG_PATH="/home/$CURRENT_USER/.kube/config"

# Remove the export statement from the appropriate shell configuration file
remove_export_statement() {
    echo "Removing export statement from $1"
    sed -i "/export KUBECONFIG=$KUBECONFIG_PATH/d" "$1"
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

# Remove the kubeconfig file and directory
rm -rf "$KUBECONFIG_PATH"
rm "$HOME/kube-vip.yaml"
rm "$HOME/ipAddressPool.yaml"

# If it's a master node, kill k3s
if [ -f "/etc/rancher/k3s.yaml" ]; then
    k3s-killall
    k3s-agent-uninstall.sh
else
    k3s-agent-uninstall.sh
fi

echo "Removal completed successfully."
