#!/bin/bash

# # Define the repository owner and name
# REPO_OWNER="cert-manager"
# REPO_NAME="cert-manager"
# DOMAIN="techcasa.io"

# # GitHub API URL for the latest release
# API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# # Use curl to fetch the latest release data
# # Note: GitHub recommends setting a User-Agent
# response=$(curl -s -H "User-Agent: MyClient/1.0.0" "$API_URL")

# # Check if the request was successful
# if echo "$response" | grep -q '"tag_name":'; then
#   # Extract the tag name which typically is the version
#   latest_version=$(echo "$response" | jq -r '.tag_name')
#   echo "Latest release version of $REPO_NAME: $latest_version"
# else
#   echo "Failed to fetch the latest release version of $REPO_NAME."
#   echo "$response"
# fi


# Helm install
if ! command -v helm version &> /dev/null
then
  echo -e " \033[31;5mHelm not found, installing\033[0m"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo -e " \033[32;5mHelm already installed\033[0m"
fi


# Kubectl
if ! command -v kubectl version &> /dev/null
then
  echo -e " \033[31;5mKubectl not found, installing\033[0m"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
  echo -e " \033[32;5mKubectl already installed\033[0m"
fi


# Step 2: Add Helm Repos
helm repo add traefik https://helm.traefik.io/traefik
helm repo update


# Step 3: Create Traefik namespace
kubectl create namespace traefik

# Step 4: Install Traefik
helm install --namespace=traefik traefik traefik/traefik -f ./helm/values.yaml

# Step 5: Check Traefik deployment
kubectl get svc -n traefik
kubectl get pods -n traefik

# Step 6: Apply Middleware
kubectl apply -f ./helm/default-headers.yaml

# Step 7: Create Secret for Traefik Dashboard
kubectl apply -f ./helm/dashboard/secret-dashboard.yaml

# Step 8: Apply Middleware
kubectl apply -f ./helm/dashboard/middleware.yaml

# Step 9: Apply Ingress to Access Service
kubectl apply -f ./helm/dashboard/ingress.yaml

source ../cert-manager/cert-manager.sh