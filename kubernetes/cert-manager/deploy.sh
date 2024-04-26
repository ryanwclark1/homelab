#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

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
  echo "Latest release version of $REPO_NAME: $latest_version"
else
  echo "Failed to fetch the latest release version of $REPO_NAME."
  echo "$response"
fi


# Step 10: Install Cert-Manager (should already have this with Rancher deployment)
# Check if we already have it by querying namespace
namespaceStatus=$(kubectl get ns cert-manager -o json | jq .status.phase -r)
if [ $namespaceStatus == "Active" ]; then
  echo -e " \033[32;5mCert-Manager already installed, upgrading with new values.yaml...\033[0m"
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm upgrade \
  cert-manager \
  jetstack/cert-manager \
  --namespace cert-manager \
  --values $WORKING_DIR/helm/values.yaml
else
  echo "Cert-Manager is not present, installing..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version ${latest_version}
fi

export $(cat .env | xargs)
envsubst < $WORKING_DIR/helm/issuers/secret-cf-token.yaml | kubectl apply -f -

# Step 11: Apply secret for certificate (Cloudflare)
kubectl apply -f $WORKING_DIR/helm/issuers/secret-cf-token.yaml

# Step 12: Apply production certificate issuer (technically you should use the staging to test as per documentation)
kubectl apply -f $WORKING_DIR/helm/issuers/letsencrypt-production.yaml

# Step 13: Apply production certificate
kubectl apply -f $WORKING_DIR/helm/production/techcasa-production.yaml