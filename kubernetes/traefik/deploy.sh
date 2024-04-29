#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="traefik"


release_exists=$(helm list -n "$NAME_SPACE" | grep 'traefik' | wc -l)

if [ "$release_exists" -eq 0 ]; then
  echo "No active release found. Installing..."
  helm repo add traefik https://helm.traefik.io/traefik
  helm repo update
  kubectl create namespace $NAME_SPACE
  helm install --namespace=traefik traefik traefik/traefik \
    --namespace $NAME_SPACE \
    --values $WORKING_DIR/helm/values.yaml
    # -f $WORKING_DIR/helm/values.yaml
else
  echo -e " \033[32;5 Release found, upgrading...\033[0m"
  helm repo update
  helm upgrade traefik traefik/traefik \
    --namespace $NAME_SPACE \
    --values $WORKING_DIR/helm/values.yaml
fi

kubectl apply -f $WORKING_DIR/helm/default-headers.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/secret-dashboard.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/middleware.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/ingress.yaml

kubectl get svc -n traefik
kubectl get pods -n traefik

kubectl expose deployment traefik --port=80 --type=LoadBalancer -n traefik