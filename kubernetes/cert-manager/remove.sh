#!/bin/bash

# Namespace where cert-manager is installed
NAME_SPACE="cert-manager"

# Confirm before proceeding
read -p "Are you sure you want to delete cert-manager from the namespace $NAME_SPACE? (yes/no) " confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Deletion cancelled."
  exit 0
fi

# Delete cert-manager using the specific namespace
echo "Deleting cert-manager resources..."
kubectl delete namespace $NAME_SPACE

# If cert-manager resources are not contained within a single namespace or need specific cleanup
echo "Deleting cluster-wide resources related to cert-manager..."

# Delete Custom Resource Definitions (CRDs) and other cluster-wide resources
kubectl delete crds --selector=app.kubernetes.io/instance=cert-manager
kubectl delete clusterissuer,issuer,certificates --all-namespaces --all

# Optionally, delete the labels and secrets if you know they won't be used elsewhere
kubectl delete secrets,configmaps --selector=app.kubernetes.io/instance=cert-manager --all-namespaces

echo "Cert-manager and related resources have been removed."
