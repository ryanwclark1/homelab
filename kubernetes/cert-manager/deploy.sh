#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="cert-manager"

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

curl -sL "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/${latest_version}/cert-manager.yaml" | kubectl apply -f -


# Check if a deployment environment was provided as an argument
ENVIRONMENT="$1"
if [ -z "$ENVIRONMENT" ]; then
  read -p "Enter the deployment environment (staging or production): " ENVIRONMENT
fi

case "$ENVIRONMENT" in
  staging)
    export $(cat "$WORKING_DIR/.env.staging" | xargs)
    ;;
  production)
    export $(cat "$WORKING_DIR/.env.production" | xargs)
    ;;
  *)
    echo "Invalid environment specified. Exiting."
    exit 1
    ;;
esac

envsubst < $WORKING_DIR/manifests/secrets/cloudflare-token-secret.yaml | kubectl apply -f -
envsubst < $WORKING_DIR/manifests/issuers/clusterissuer-${ENVIRONMENT}.yaml | kubectl apply -f -

kubectl apply -f $WORKING_DIR/manifests/certificates/techcasa-io-${ENVIRONMENT}.yaml

kubectl get svc -n "$NAME_SPACE"
kubectl get pods -n "$NAME_SPACE"
kubectl get clusterissuer letsencrypt-${ENVIRONMENT} -o yaml

# Testing the deployment status
echo "Checking status of deployed resources:"
echo "Challenges:"
kubectl get challenges -n "$NAME_SPACE"
echo "Orders:"
kubectl get orders -n "$NAME_SPACE"
echo "Certificates:"
kubectl get certificates -n "$NAME_SPACE"

# Additional details on the first found order
ORDER_NAME=$(kubectl get orders -n "$NAME_SPACE" -o jsonpath="{.items[0].metadata.name}")
if [ -n "$ORDER_NAME" ]; then
  echo "Describing order: $ORDER_NAME"
  kubectl describe order "$ORDER_NAME" -n "$NAME_SPACE"
else
  echo "No orders found in namespace $NAME_SPACE."
fi

# Details on the associated challenge, if any
CHALLENGE_NAME=$(kubectl get challenges -n "$NAME_SPACE" -o jsonpath="{.items[0].metadata.name}")
if [ -n "$CHALLENGE_NAME" ]; then
  echo "Describing challenge: $CHALLENGE_NAME"
  kubectl describe challenge "$CHALLENGE_NAME" -n "$NAME_SPACE"
else
  echo "No challenges found in namespace $NAME_SPACE."
fi