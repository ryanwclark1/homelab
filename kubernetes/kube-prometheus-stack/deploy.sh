#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

REPO_OWNER="prometheus-community"
REPO_NAME="kube-prometheus-stack"

# URL of the RSS feed
API_URL="https://artifacthub.io/api/v1/packages/helm/$REPO_OWNER/$REPO_NAME/feed/rss"

# Fetch the latest version number using curl and parse it using xmllint
response=$(curl -s "$API_URL")

# Check if the curl command succeeded
if [ $? -eq 0 ]; then
  echo "Response received, checking content..."
  # Check if the response contains <title> tags
  if echo "$response" | grep -q '<title>'; then
    echo "Valid response, processing..."
    latest_version=$(echo "$response" | xmllint --xpath 'string(//rss/channel/item[1]/title)' -)
    if [ -n "$latest_version" ]; then
      echo "Latest release version of $REPO_NAME: $latest_version"
    else
      echo "Failed to extract version, please check the XML structure and XPath."
    fi
  else
    echo "Invalid response, no <title> tags found."
    echo "$response"
  fi
else
  echo "Failed to fetch the RSS feed."
  echo "$response"
fi

# kubectl create secret generic grafana-admin-credentials


# # More information: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo update

# kubectl create namespace kube-prometheus-stack
# helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
#   --namespace kube-prometheus-stack \
#   --values $WORKING_DIR/helm/values.yaml \
#   --version ${latest_version}

