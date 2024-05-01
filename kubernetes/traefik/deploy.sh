#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

NAME_SPACE="traefik"

release_exists=$(helm list -n "$NAME_SPACE" | grep 'traefik' | wc -l)

echo -e " \033[32;5mInstalling Traefik\033[0m"
if [ "$release_exists" -eq 0 ]; then
  echo "No active release found. Installing..."
  helm repo add traefik https://traefik.github.io/charts
  helm repo update
  kubectl create namespace $NAME_SPACE
  helm install traefik traefik/traefik -n $NAME_SPACE \
    -f $WORKING_DIR/helm/values.yaml
else
  echo -e " \033[32;5 Release found, upgrading...\033[0m"
  helm repo update
  helm upgrade --install traefik traefik/traefik  -n $NAME_SPACE \
    -f $WORKING_DIR/helm/values.yaml
fi

kubectl apply -f $WORKING_DIR/helm/default-headers.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/secret-dashboard.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/middleware.yaml
kubectl apply -f $WORKING_DIR/helm/dashboard/ingress.yaml

kubectl get svc -n $NAME_SPACE
kubectl get pods -n $NAME_SPACE
