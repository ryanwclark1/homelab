#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

kubectl apply -f "$WORKING_DIR/namespace.yaml"

# Can use create or apply --server-side
kubectl create -f "$WORKING_DIR/crds"
kubectl get crds

kubectl apply -f "$WORKING_DIR/rbac"

kubectl apply -f "$WORKING_DIR/deployment"

kubectl wait --for=condition=Ready pods -l  app.kubernetes.io/name=prometheus-operator -n monintoring

kubectl get pods -n monitoring
