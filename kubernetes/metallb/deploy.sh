#!/bin/bash
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

NAME_SPACE="metallb-system"
lbrange=$(jq -r '.lbrange' "$inventory")

if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
  echo -e "Namespace '$NAME_SPACE' namespace exists, updating IP Address Pool and L2Advertisement..."
else
  echo -e "Applying MetalLB to '$NAME_SPACE' namespace..."
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
fi

kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s

# https://metallb.universe.tf/configuration/
# Deploy IPAddressPool
cat << EOF | kubectl apply -f -
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: first-pool
    namespace: metallb-system
  spec:
    addresses:
    - $lbrange
EOF

kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s

# Deploy l2Advertisement
cat << EOF | kubectl apply -f -
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    name: example
    namespace: metallb-system
  spec:
    ipAddressPools:
    - first-pool
EOF