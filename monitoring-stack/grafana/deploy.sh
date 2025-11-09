#!/usr/bin/env bash

# Deploy Grafana with integrated data sources

set -e
set -x
set -o pipefail

NAMESPACE="monitoring-stack"
RELEASE_NAME="grafana"

# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade Grafana
helm upgrade --install "$RELEASE_NAME" grafana/grafana \
  --namespace "$NAMESPACE" \
  --values helm/values.yaml \
  --wait

echo "✓ Grafana deployed successfully"
echo ""
echo "Access Grafana:"
echo "  URL: https://grafana.techcasa.io"
echo ""
echo "Get admin password:"
echo "  kubectl get secret -n $NAMESPACE grafana -o jsonpath='{.data.admin-password}' | base64 --decode ; echo"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana"
echo ""
echo "Port-forward for local access:"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "  Then visit: http://localhost:3000"
