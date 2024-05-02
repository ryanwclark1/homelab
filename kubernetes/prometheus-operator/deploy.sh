#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

create_namespace() {
  if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
    echo -e "Namespace '$NAME_SPACE' namespace exists, checking installation status..."
  else
    echo "Namespace '$NAME_SPACE' does not exist, creating it..."
    kubectl apply -f "$WORKING_DIR/namespace.yaml"
    # kubectl create namespace "$NAME_SPACE"
  fi
}

create_secret


# Can use create or apply --server-side
kubectl  apply --server-side -f "$WORKING_DIR/crds"
kubectl get crds

kubectl apply -f "$WORKING_DIR/rbac"

kubectl apply -f "$WORKING_DIR/deployment"

kubectl wait --for=condition=Ready pods -l  app.kubernetes.io/name=prometheus-operator -n $NAME_SPACE

kubectl get pods -n $WORKING_DIR
