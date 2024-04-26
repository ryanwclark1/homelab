#!/bin/bash

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
