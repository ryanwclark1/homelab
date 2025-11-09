#!/usr/bin/env bash

# Master deployment script for complete monitoring stack
# Deploys: Loki → Tempo → Alloy → Grafana

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring-stack"

echo "════════════════════════════════════════════════════════════════"
echo "  Deploying Complete Monitoring Stack"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Components:"
echo "  • Loki   - Log aggregation"
echo "  • Tempo  - Distributed tracing"
echo "  • Alloy  - Telemetry collector"
echo "  • Grafana - Visualization"
echo ""
echo "Namespace: $NAMESPACE"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Create namespace
echo "→ Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace ready"
echo ""

# Deploy Loki (logs)
echo "════════════════════════════════════════════════════════════════"
echo "→ Deploying Loki..."
echo "════════════════════════════════════════════════════════════════"
cd "$SCRIPT_DIR/loki"
./deploy.sh
echo ""

# Deploy Tempo (traces)
echo "════════════════════════════════════════════════════════════════"
echo "→ Deploying Tempo..."
echo "════════════════════════════════════════════════════════════════"
cd "$SCRIPT_DIR/tempo"
./deploy.sh
echo ""

# Deploy Alloy (collector)
echo "════════════════════════════════════════════════════════════════"
echo "→ Deploying Alloy..."
echo "════════════════════════════════════════════════════════════════"
cd "$SCRIPT_DIR/alloy"
./deploy.sh
echo ""

# Deploy Grafana (visualization)
echo "════════════════════════════════════════════════════════════════"
echo "→ Deploying Grafana..."
echo "════════════════════════════════════════════════════════════════"
cd "$SCRIPT_DIR/grafana"
./deploy.sh
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "  ✓ Monitoring Stack Deployment Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Access Points:"
echo "  • Grafana:  https://grafana.techcasa.io"
echo ""
echo "Get Grafana admin password:"
echo "  kubectl get secret -n $NAMESPACE grafana -o jsonpath='{.data.admin-password}' | base64 --decode ; echo"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "View all services:"
echo "  kubectl get svc -n $NAMESPACE"
echo ""
echo "Next steps:"
echo "  1. Access Grafana and log in with admin credentials"
echo "  2. Verify data sources are working (Prometheus, Loki, Tempo)"
echo "  3. Explore pre-installed dashboards"
echo "  4. Configure alerting in Grafana"
echo ""
