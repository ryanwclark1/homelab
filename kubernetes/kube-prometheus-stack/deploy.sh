#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

REPO_OWNER="prometheus-community"
REPO_NAME="kube-prometheus-stack"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"


# URL of the RSS feed
API_URL="https://artifacthub.io/api/v1/packages/helm/$REPO_OWNER/$REPO_NAME/feed/rss"

# Fetch the latest version number using curl and parse it using xmllint
latest_version=$(curl -s $API_URL | xmllint --xpath 'string(//rss/channel/item[1]/title)' -)

# More information: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace kube-prometheus-stack \
  --values $WORKING_DIR/helm/values.yaml \
  --version ${latest_version}

