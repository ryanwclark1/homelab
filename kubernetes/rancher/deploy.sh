#!/bin/bash
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="cattle-system"
domain=$(jq -r '.domain' "$inventory")

# Ensure the namespace exists before proceeding
if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
  echo -e "Namespace '$NAME_SPACE' namespace exists, checking installation status..."
else
  echo "Namespace '$NAME_SPACE' does not exist, creating it..."
  kubectl create namespace "$NAME_SPACE"
fi

# Ensure the helm repo is added and updated
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Check the installation status of Rancher
if ! kubectl get deployment -n "$NAME_SPACE" | grep -q 'rancher'; then
  echo "No active Rancher release found. Installing..."
  helm install rancher rancher-latest/rancher -n "$NAME_SPACE" \
    -f "$WORKING_DIR/helm/values.yaml"
else
  echo "Rancher release found, upgrading..."
  helm upgrade --install rancher rancher-latest/rancher -n "$NAME_SPACE" \
    -f "$WORKING_DIR/helm/values.yaml"
fi

kubectl apply -f "$WORKING_DIR/helm/ingress.yaml"
# kubectl apply -f "$WORKING_DIR/helm/certificate.yaml"
kubectl -n "$NAME_SPACE" rollout status deploy/rancher
kubectl -n "$NAME_SPACE" get deploy rancher
kubectl get svc -n "$NAME_SPACE"

# Expose Rancher via Loadbalancer
# kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system


# Profit: Go to Rancher GUI
echo -e " \033[32;5mHit the url… and create your account\033[0m"
echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"
