#!/usr/bin/env bash
# Script to help create Proxmox API tokens
# Run this script on your Proxmox host

set -e

echo "==================================="
echo "Proxmox API Token Creation Helper"
echo "==================================="
echo ""

# Check if running on Proxmox
if ! command -v pveum &> /dev/null; then
    echo "Error: This script must be run on a Proxmox host"
    exit 1
fi

# Default values
USER="root@pam"
TOKEN_NAME="terraform"
COMMENT="Terraform automation token"

echo "Creating API token for Terraform..."
echo "User: $USER"
echo "Token name: $TOKEN_NAME"
echo ""

# Create the token
echo "Creating token..."
TOKEN_OUTPUT=$(pveum user token add "$USER" "$TOKEN_NAME" --comment "$COMMENT" --privsep 0)

echo ""
echo "✓ Token created successfully!"
echo ""
echo "================================================"
echo "IMPORTANT: Save these credentials securely!"
echo "================================================"
echo ""
echo "$TOKEN_OUTPUT"
echo ""
echo "Add these to your terraform.tfvars file:"
echo ""
echo "proxmox_api_token_id     = \"$USER!$TOKEN_NAME\""
echo "proxmox_api_token_secret = \"<secret-from-output-above>\""
echo ""
echo "================================================"
echo ""

# Set permissions
echo "Setting permissions for the token..."
pveum acl modify / --users "$USER" --roles Administrator

echo "✓ Permissions set successfully!"
echo ""
echo "Your API token is ready to use with Terraform."
