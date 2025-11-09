#!/usr/bin/env bash

# Deploy Grafana Loki log aggregation system

set -e
set -x
set -o pipefail

NAMESPACE="monitoring-stack"
RELEASE_NAME="loki"

# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade Loki
helm upgrade --install "$RELEASE_NAME" grafana/loki \
  --namespace "$NAMESPACE" \
  --values helm/values.yaml \
  --wait

echo "✓ Grafana Loki deployed successfully"
echo ""
echo "Endpoints:"
echo "  - Gateway:   loki-gateway.$NAMESPACE.svc.cluster.local"
echo "  - Push API:  http://loki-gateway.$NAMESPACE.svc.cluster.local/loki/api/v1/push"
echo "  - Query API: http://loki-gateway.$NAMESPACE.svc.cluster.local/loki/api/v1/query"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=loki"
echo ""
echo "Test log query:"
echo "  kubectl port-forward -n $NAMESPACE svc/loki-gateway 3100:80"
echo "  curl http://localhost:3100/loki/api/v1/labels"
