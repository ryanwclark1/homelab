#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="cert-manager"

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
  echo "Latest release version of $REPO_NAME: $latest_version"
else
  echo "Failed to fetch the latest release version of $REPO_NAME."
  echo "$response"
  exit 1
fi

# Ensure the namespace exists before proceeding
if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
  echo -e "\033[32;5mCert-Manager namespace exists, checking installation status...\033[0m"
else
  echo "Namespace '$NAME_SPACE' does not exist, creating it..."
  kubectl create namespace "$NAME_SPACE"
fi

# Check if we already have it by querying namespace
if kubectl get deployment -n "$NAME_SPACE" | grep -q 'cert-manager'; then
  echo -e " \033[32;5mCert-Manager already installed, upgrading with new values.yaml...\033[0m"
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm upgrade cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --values $WORKING_DIR/helm/values.yaml \
  --version ${latest_version}
else
  echo "Cert-Manager is not present, installing..."
  kubectl create namespace $NAME_SPACE
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --values $WORKING_DIR/helm/values.yaml \
  --version ${latest_version}
fi

export $(cat $WORKING_DIR/.env | xargs)
envsubst < $WORKING_DIR/helm/issuers/secret-cf-token.yaml | kubectl apply -f -
kubectl apply -f $WORKING_DIR/helm/issuers/secret-cf-token.yaml
kubectl apply -f $WORKING_DIR/helm/issuers/letsencrypt-staging.yaml
kubectl apply -f $WORKING_DIR/helm/staging/techcasa-staging.yaml

kubectl get svc -n $NAME_SPACE
kubectl get pods -n $NAME_SPACE