#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

# NAME_SPACE="cert-manager"

REPO_OWNER="prometheus-operator"
REPO_NAME="prometheus-operator"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
response=$(curl -s -H "User-Agent: MyClient/1.0.0" "$API_URL")
prometheus_operator_version=v0.73.2

github_version() {
  if echo "$response" | grep -q '"tag_name":'; then
    # Extract the tag name which typically is the version
    latest_version=$(echo "$response" | jq -r '.tag_name')
    echo "Latest release version of $REPO_NAME: $latest_version"
  else
    echo "Failed to fetch the latest release version of $REPO_NAME."
    echo "$response"
    exit 1
  fi
}

read -p "Do you want to download a new version? (y/n): " answer

# Check user input
if [ "$answer" == "y" ]; then
    # Prompt user to enter the new version
    read -p "Enter the new version number: " new_version
    prometheus_operator_version=$latest_version
fi


cd ~
git clone https://github.com/prometheus-operator/prometheus-operator.git
cd ~/prometheus-operator
git checkout tags/$prometheus_operator_version
cp -a ~/prometheus-operator/example/prometheus-operator-crd/ $WORKING_DIR/crds