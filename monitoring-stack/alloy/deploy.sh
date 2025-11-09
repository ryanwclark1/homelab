#!/usr/bin/env bash

# Deploy Grafana Alloy telemetry collector
# Alloy collects metrics, logs, and traces from Kubernetes

set -e
set -x
set -o pipefail

NAMESPACE="monitoring-stack"
RELEASE_NAME="alloy"

# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade Grafana Alloy
helm upgrade --install "$RELEASE_NAME" grafana/alloy \
  --namespace "$NAMESPACE" \
  --values helm/values.yaml \
  --wait

echo "✓ Grafana Alloy deployed successfully"
echo ""
echo "Endpoints:"
echo "  - OTLP gRPC: alloy.$NAMESPACE.svc.cluster.local:4317"
echo "  - OTLP HTTP: alloy.$NAMESPACE.svc.cluster.local:4318"
echo "  - Metrics:   alloy.$NAMESPACE.svc.cluster.local:12345/metrics"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=alloy"
echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=alloy -f"
