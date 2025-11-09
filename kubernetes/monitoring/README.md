# Kubernetes Monitoring Stack

This directory contains the configuration for deploying the kube-prometheus-stack to your Kubernetes cluster.

## Overview

The monitoring stack uses **Helm** to deploy:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and notifications
- **kube-state-metrics**: Kubernetes object metrics
- **node-exporter**: Node-level metrics
- **prometheus-adapter**: Custom metrics API for HPA

## Components

### Helm Values

The `values.yaml` file contains the configuration for the kube-prometheus-stack Helm chart:
- Prometheus retention: 30 days
- Prometheus storage: 50Gi
- Grafana storage: 10Gi
- Alertmanager storage: 10Gi
- External URLs for each component

### IngressRoutes

Traefik IngressRoutes are configured for:
- **Grafana**: https://grafana.techcasa.io
- **Prometheus**: https://prometheus.techcasa.io
- **Alertmanager**: https://alertmanager.techcasa.io

All routes use TLS with the `techcasa-io-production-tls` certificate.

## Deployment

### Prerequisites

1. Kubernetes cluster is running
2. Helm 3.x is installed
3. Traefik ingress controller is deployed
4. cert-manager is configured for TLS certificates

### Deploy the Stack

Run the deployment script:

```bash
./deploy-helm.sh
```

Or deploy manually:

```bash
# Add Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install/upgrade the stack
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml \
  --wait

# Apply IngressRoutes
kubectl apply -k manifests/
```

### Using Ansible

If you've configured the Ansible automation, deploy with:

```bash
cd ../../ansible
make k3s-monitoring
```

## Accessing the UIs

After deployment, access the monitoring UIs:

- **Grafana**: https://grafana.techcasa.io
  - Default username: `admin`
  - Password: Set in `values.yaml` or override with `--set grafana.adminPassword=<password>`

- **Prometheus**: https://prometheus.techcasa.io
  - Query and explore metrics

- **Alertmanager**: https://alertmanager.techcasa.io
  - Manage alert routing and silences

## Customization

### Update Grafana Admin Password

```bash
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml \
  --set grafana.adminPassword=<new-password> \
  --reuse-values
```

### Adjust Storage Sizes

Edit `values.yaml` and update:
- `prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage`
- `grafana.persistence.size`
- `alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage`

Then upgrade the release:

```bash
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml
```

## Monitoring Custom Applications

### Add ServiceMonitor

Create a ServiceMonitor to scrape your application:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      interval: 30s
```

### Add PrometheusRule

Create custom alerts:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-app-alerts
  namespace: monitoring
spec:
  groups:
    - name: my-app
      rules:
        - alert: MyAppDown
          expr: up{job="my-app"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "My app is down"
```

## Troubleshooting

### Check Helm Release Status

```bash
helm status kube-prometheus-stack -n monitoring
```

### View Prometheus Targets

```bash
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090
```

Then visit http://localhost:9090/targets

### Check ServiceMonitor Discovery

```bash
kubectl get servicemonitors -A
kubectl describe servicemonitor <name> -n <namespace>
```

### View Logs

```bash
# Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Alertmanager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
```

## Migration from Jsonnet

This deployment replaces the previous jsonnet-based build process with a simpler Helm-based approach.

**Old process:**
- Required jsonnet, jsonnet-bundler, gojsontoyaml
- Complex build scripts
- Manual manifest generation

**New process:**
- Standard Helm chart
- Simple values.yaml configuration
- One-command deployment

The `monitoring.jsonnet` file and build scripts are kept for reference but are no longer used.
