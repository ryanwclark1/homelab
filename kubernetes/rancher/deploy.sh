#!/bin/bash


#!/bin/bash

# Define the repository owner and name
REPO_OWNER="cert-manager"
REPO_NAME="cert-manager"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# Use curl to fetch the latest release data
# Note: GitHub recommends setting a User-Agent
response=$(curl -s -H "User-Agent: MyClient/1.0.0" "$API_URL")

# Check if the request was successful
if echo "$response" | grep -q '"tag_name":'; then
    # Extract the tag name which typically is the version
    latest_version=$(echo "$response" | jq -r '.tag_name')
    echo "Latest release version: $latest_version"
else
    echo "Failed to fetch the latest release version."
    echo "$response"
fi

# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
