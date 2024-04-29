#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)
DOMAIN="techcasa.io"

NAME_SPACE="cattle-system"

release_exists=$(helm list -n "$NAME_SPACE" | grep 'rancher' | wc -l)

if [ "$release_exists" -eq 0 ]; then
  echo "No active release found. Installing..."

  # Add rancher helm repo
  helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
  helm repo update

  kubectl create namespace cattle-system
  helm install rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname=rancher.${DOMAIN} \
    --set replicas=1 \
    --set bootstrapPassword=password123
  kubectl -n cattle-system rollout status deploy/rancher
  kubectl -n cattle-system get deploy rancher
  kubectl apply -f $WORKING_DIR/helm/ingress.yaml
else
  echo -e " \033[32;5 Release found, upgrading...\033[0m"
  helm upgrade rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname=rancher.${DOMAIN} \
    --set replicas=1
  kubectl -n cattle-system get deploy rancher
  kubectl apply -f $WORKING_DIR/helm/ingress.yaml
fi

# Expose Rancher via Loadbalancer
# kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=80 --type=LoadBalancer -n cattle-system
# kubectl expose deployment rancher --name=rancher-lb2 --port=80 --type=LoadBalancer -n cattle-system
kubectl get svc -n cattle-system

# Profit: Go to Rancher GUI
echo -e " \033[32;5mHit the url… and create your account\033[0m"
echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"
