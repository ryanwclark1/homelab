#!/usr/bin/env bash

# Deploy Grafana Tempo distributed tracing backend

set -e
set -x
set -o pipefail

NAMESPACE="monitoring-stack"
RELEASE_NAME="tempo"

# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade Tempo
helm upgrade --install "$RELEASE_NAME" grafana/tempo-distributed \
  --namespace "$NAMESPACE" \
  --values helm/values.yaml \
  --wait

echo "✓ Grafana Tempo deployed successfully"
echo ""
echo "Endpoints:"
echo "  - OTLP gRPC:     tempo-distributor.$NAMESPACE.svc.cluster.local:4317"
echo "  - OTLP HTTP:     tempo-distributor.$NAMESPACE.svc.cluster.local:4318"
echo "  - Jaeger gRPC:   tempo-distributor.$NAMESPACE.svc.cluster.local:14250"
echo "  - Jaeger HTTP:   tempo-distributor.$NAMESPACE.svc.cluster.local:14268"
echo "  - Zipkin:        tempo-distributor.$NAMESPACE.svc.cluster.local:9411"
echo "  - Query:         tempo-query-frontend.$NAMESPACE.svc.cluster.local:3100"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=tempo"
echo ""
echo "Test trace query:"
echo "  kubectl port-forward -n $NAMESPACE svc/tempo-query-frontend 3100:3100"
echo "  curl http://localhost:3100/api/search"
