#!/bin/bash

# Define the repository owner and name
REPO_OWNER="cert-manager"
REPO_NAME="cert-manager"
DOMAIN="techcasa.io"

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


# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# Helm install
if ! command -v helm version &> /dev/null
then
  echo -e " \033[31;5mHelm not found, installing\033[0m"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo -e " \033[32;5mHelm already installed\033[0m"
fi

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version ${latest_version}
kubectl get pods --namespace cert-manager

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.${DOMAIN} \
  --set bootstrapPassword=password123
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher

kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system
kubectl get svc -n cattle-system