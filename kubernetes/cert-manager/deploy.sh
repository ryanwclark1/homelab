#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="cert-manager"
CERT_NAME_SPACE="default"

REPO_OWNER="cert-manager"
REPO_NAME="cert-manager"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
response=$(curl -s -H "User-Agent: MyClient/1.0.0" "$API_URL")

if echo "$response" | grep -q '"tag_name":'; then
  # Extract the tag name which typically is the version
  latest_version=$(echo "$response" | jq -r '.tag_name')
  echo "Latest release version of $REPO_NAME: $latest_version"
else
  echo "Failed to fetch the latest release version of $REPO_NAME."
  echo "$response"
  exit 1
fi

kubectl apply -f "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/${latest_version}/cert-manager.yaml"

export $(cat "$WORKING_DIR/.env" | xargs)
envsubst < $WORKING_DIR/manifests/secrets/cloudflare-token-secret.yaml | kubectl apply -f -
envsubst < $WORKING_DIR/manifests/issuers/clusterissuer-staging.yaml | kubectl apply -f -
envsubst < $WORKING_DIR/manifests/certificates/techcasa-io-staging.yaml | kubectl apply -f -

kubectl get svc -n "$NAME_SPACE"
kubectl get pods -n "$NAME_SPACE"
kubectl get clusterissuer letsencrypt-staging -o yaml
# kubectl get challenges -n "$CERT_NAME_SPACE"
# kubectl describe order $(kubectl get challenges -n "$CERT_NAME_SPACE" -o jsonpath="{.items[0].metadata.ownerReferences[0].name}") -n "$CERT_NAME_SPACE"