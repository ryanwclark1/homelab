#!/bin/bash

#!/bin/bash
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="longhorn-system"
domain=$(jq -r '.domain' "$inventory")

# Ensure the namespace exists before proceeding
if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
  echo -e "Namespace '$NAME_SPACE' namespace exists, checking installation status..."
else
  echo "Namespace '$NAME_SPACE' does not exist, creating it..."
  kubectl create namespace "$NAME_SPACE"
fi

# Ensure the helm repo is added and updated
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Check the installation status of Rancher
if ! kubectl get deployment -n "$NAME_SPACE" | grep -q 'longhorn'; then
  echo "No active longhorn release found. Installing..."
  helm install longhorn longhorn/longhorn -n "$NAME_SPACE" \
    -f "$WORKING_DIR/helm/values.yaml"
else
  echo "Rancher release found, upgrading..."
  helm upgrade --install longhorn longhorn/longhorn -n "$NAME_SPACE" \
    -f "$WORKING_DIR/helm/values.yaml"
fi

kubectl apply -f "$WORKING_DIR/helm/ingress.yaml"
kubectl -n "$NAME_SPACE" rollout status deploy/longhorn
kubectl -n "$NAME_SPACE" get deploy longhorn
kubectl get svc -n "$NAME_SPACE"

# Profit: Go to Rancher GUI
echo -e " \033[32;5mHit the url… and create your account\033[0m"
echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"


# # Perform the find and replace
# sed -i 's/priority-class: longhorn-critical/system-managed-components-node-selector: longhorn=true/' "$LH_FILE_NAME"
# if [ $? -ne 0 ]; then
#   echo "Error replacing the text."
#   exit 1
# fi
