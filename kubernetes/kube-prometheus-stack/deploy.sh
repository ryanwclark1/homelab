#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="kube-prometheus-stack"

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

# Create secret using .env file
if [ -f "$WORKING_DIR/.env" ]; then
  kubectl create secret generic grafana-admin-credentials \
  --from-env-file="$WORKING_DIR/.env" \
  --namespace $NAME_SPACE
  echo "Grafana admin credentials created successfully."
else
  echo "No .env file found at $WORKING_DIR"
  exit 1
fi

echo -e " \033[32;5mGrafana admin credentials\033[0m"
kubectl describe secret -n $NAME_SPACE grafana-admin-credentials
echo -e "\n\n\033[32;5mGrafana user name\033[0m\n"
kubectl get secret -n $NAME_SPACE grafana-admin-credentials -o jsonpath="{.data.GF_ADMIN_USER}" | base64 --decode

echo -e "\n\n\033[32;5mGrafana password\033[0m\n"
kubectl get secret -n $NAME_SPACE grafana-admin-credentials -o jsonpath="{.data.GF_ADMIN_PASSWORD}" | base64 --decode
echo -e "\n"

# More information: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md

namespaceStatus=""
namespaceStatus=$(kubectl get ns "$NAME_SPACE" -o json | jq .status.phase -r)
if [ $namespaceStatus == "Active" ]; then
  echo -e " \033[32;5m$NAME_SPACE already installed, upgrading with new values.yaml...\033[0m"
  helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAME_SPACE \
  --values $WORKING_DIR/helm/values.yaml \
  --version ${latest_version}
else
  echo "$NAME_SPACE is not present, installing..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  kubectl create namespace $NAME_SPACE
  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAME_SPACE \
  --values $WORKING_DIR/helm/values.yaml \
  --version ${latest_version}
fi