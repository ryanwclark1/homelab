#!/usr/bin/env bash

# Deploy kube-prometheus-stack using Helm
# This replaces the jsonnet-based build process

set -e
set -x
set -o pipefail

# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install/upgrade kube-prometheus-stack
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml \
  --wait

# Apply IngressRoutes
kubectl apply -k manifests/

echo "✓ Monitoring stack deployed successfully"
echo "  - Grafana: https://grafana.techcasa.io"
echo "  - Prometheus: https://prometheus.techcasa.io"
echo "  - Alertmanager: https://alertmanager.techcasa.io"
