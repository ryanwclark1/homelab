#!/bin/bash

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

# Step 2: Add Helm Repos
helm repo add traefik https://helm.traefik.io/traefik
helm repo update


# Step 3: Create Traefik namespace
kubectl create namespace traefik

# Step 4: Install Traefik
helm install --namespace=traefik traefik traefik/traefik -f $WORKING_DIR/helm/values.yaml

# Step 5: Check Traefik deployment
kubectl get svc -n traefik
kubectl get pods -n traefik

# Step 6: Apply Middleware
kubectl apply -f $WORKING_DIR/helm/default-headers.yaml

# Step 7: Create Secret for Traefik Dashboard
kubectl apply -f $WORKING_DIR/helm/dashboard/secret-dashboard.yaml

# Step 8: Apply Middleware
kubectl apply -f $WORKING_DIR/helm/dashboard/middleware.yaml

# Step 9: Apply Ingress to Access Service
kubectl apply -f $WORKING_DIR/helm/dashboard/ingress.yaml

kubectl expose deployment traefik --port=80 --type=LoadBalancer -n traefik