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

release_exists=$(helm list -n "$NAME_SPACE" | grep 'rancher' | wc -l)
if [ "$release_exists" -eq 0 ]; then
  echo "No active release found. Installing..."
  helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
  helm repo update
  kubectl create namespace $NAME_SPACE
  helm install rancher rancher-latest/rancher \
    --namespace $NAME_SPACE \
    --set hostname=rancher.${domain} \
    --set replicas=3 \
    --set bootstrapPassword=password123 \
    --set ingress.tls.source=secret \
    --set privateCA=true \
    --set additionalTrustedCAs=true \

else
  echo -e " \033[32;5 Release found, upgrading...\033[0m"
  helm upgrade rancher rancher-latest/rancher \
    --namespace $NAME_SPACE \
    --set hostname=rancher.${domain} \
    --set replicas=3 \
    --set ingress.enabled=false \
    --set privateCA=true \
    --set additionalTrustedCAs=true
fi

kubectl apply -f $WORKING_DIR/helm/ingress.yaml

kubectl -n $NAME_SPACE rollout status deploy/rancher
kubectl -n $NAME_SPACE get deploy rancher


# Expose Rancher via Loadbalancer
# kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=80 --type=LoadBalancer -n cattle-system
kubectl get svc -n $NAME_SPACE

# Profit: Go to Rancher GUI
echo -e " \033[32;5mHit the url… and create your account\033[0m"
echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"
