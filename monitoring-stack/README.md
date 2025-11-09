# Complete Monitoring Stack

A comprehensive observability platform for Kubernetes using the Grafana stack: metrics, logs, and traces all in one place.

## Overview

This monitoring stack provides complete observability with:

- **📊 Metrics**: Prometheus (via kube-prometheus-stack)
- **📝 Logs**: Loki
- **🔍 Traces**: Tempo
- **🎯 Collection**: Grafana Alloy
- **📈 Visualization**: Grafana

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Applications                             │
│                    (Kubernetes Workloads)                        │
└─────────────┬───────────────────────────────────────────────────┘
              │
              │ Metrics, Logs, Traces
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Grafana Alloy                               │
│              (Telemetry Collector & Processor)                   │
└──┬──────────────────────┬────────────────────┬──────────────────┘
   │                      │                    │
   │ Metrics              │ Logs               │ Traces
   ▼                      ▼                    ▼
┌──────────┐      ┌──────────────┐     ┌──────────────┐
│Prometheus│      │     Loki     │     │    Tempo     │
│  (via    │      │    (Log      │     │ (Distributed │
│   kube-  │      │ Aggregation) │     │   Tracing)   │
│prometheus│      └──────────────┘     └──────────────┘
│  stack)  │              │                    │
└──────────┘              │                    │
     │                    │                    │
     └────────────────────┴────────────────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │   Grafana    │
                  │(Visualization)│
                  └──────────────┘
```

## Components

### 1. Grafana Alloy

**Purpose**: Next-generation telemetry collector (replaces Grafana Agent)

**Features**:
- Collects metrics from Kubernetes pods
- Scrapes logs from containers
- Receives traces via OTLP, Jaeger, Zipkin
- Processes and forwards to Loki, Tempo, and Prometheus
- High availability with clustering

**Endpoints**:
- OTLP gRPC: `alloy.monitoring-stack.svc.cluster.local:4317`
- OTLP HTTP: `alloy.monitoring-stack.svc.cluster.local:4318`
- Metrics: `alloy.monitoring-stack.svc.cluster.local:12345/metrics`

### 2. Loki

**Purpose**: Horizontally scalable log aggregation

**Features**:
- SimpleScalable deployment mode (2 replicas each: read, write, backend)
- 31-day log retention
- Label-based indexing (like Prometheus)
- LogQL query language
- Integration with Tempo for trace-to-log correlation

**Endpoints**:
- Gateway: `loki-gateway.monitoring-stack.svc.cluster.local`
- Push API: `http://loki-gateway.monitoring-stack.svc.cluster.local/loki/api/v1/push`
- Query API: `http://loki-gateway.monitoring-stack.svc.cluster.local/loki/api/v1/query`

### 3. Tempo

**Purpose**: High-volume distributed tracing backend

**Features**:
- Distributed deployment mode
- 30-day trace retention
- Support for OTLP, Jaeger, and Zipkin protocols
- Metrics generation from traces
- Service graph generation
- Integration with Loki for log correlation

**Endpoints**:
- OTLP gRPC: `tempo-distributor.monitoring-stack.svc.cluster.local:4317`
- OTLP HTTP: `tempo-distributor.monitoring-stack.svc.cluster.local:4318`
- Jaeger gRPC: `tempo-distributor.monitoring-stack.svc.cluster.local:14250`
- Jaeger HTTP: `tempo-distributor.monitoring-stack.svc.cluster.local:14268`
- Zipkin: `tempo-distributor.monitoring-stack.svc.cluster.local:9411`
- Query: `tempo-query-frontend.monitoring-stack.svc.cluster.local:3100`

### 4. Grafana

**Purpose**: Unified visualization and dashboarding

**Features**:
- Pre-configured data sources (Prometheus, Loki, Tempo)
- Automatic correlation between metrics, logs, and traces
- Pre-installed dashboards
- Unified alerting
- Explore mode for ad-hoc queries

**Access**:
- URL: `https://grafana.techcasa.io`
- Default user: `admin`
- Password: Set during deployment or retrieve from secret

## Deployment

### Prerequisites

1. **Kubernetes cluster** running K3s or similar
2. **Helm 3.x** installed
3. **kubectl** configured
4. **Prometheus** deployed (from kube-prometheus-stack in `../kubernetes/monitoring/`)
5. **Traefik** ingress controller (for Grafana ingress)
6. **cert-manager** for TLS certificates (optional)
7. **StorageClass** for persistent volumes

### Quick Start

Deploy the entire stack:

```bash
./deploy-all.sh
```

This script deploys components in order:
1. Loki (logs)
2. Tempo (traces)
3. Alloy (collector)
4. Grafana (visualization)

### Individual Component Deployment

Deploy components individually:

```bash
# Loki
cd loki && ./deploy.sh

# Tempo
cd tempo && ./deploy.sh

# Alloy
cd alloy && ./deploy.sh

# Grafana
cd grafana && ./deploy.sh
```

### Using Ansible

If you have Ansible automation configured:

```bash
cd ../ansible
make monitoring-stack-deploy
```

## Configuration

### Storage

All components use persistent volumes. Update `storageClassName` in `helm/values.yaml` files:

```yaml
persistence:
  enabled: true
  size: 10Gi
  storageClassName: "longhorn"  # or your StorageClass
```

### Retention Periods

**Loki** (`loki/helm/values.yaml`):
```yaml
loki:
  limits_config:
    retention_period: 744h  # 31 days
```

**Tempo** (`tempo/helm/values.yaml`):
```yaml
tempo:
  retention:
    max_age: 720h  # 30 days
```

### Resource Limits

Adjust resources in each component's `helm/values.yaml`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Grafana Admin Password

Set during deployment:

```bash
helm upgrade grafana grafana/grafana \
  --namespace monitoring-stack \
  --set adminPassword=your-secure-password \
  --reuse-values
```

Or retrieve existing password:

```bash
kubectl get secret -n monitoring-stack grafana \
  -o jsonpath='{.data.admin-password}' | base64 --decode ; echo
```

## Instrumentation

### Application Metrics

Applications exposing Prometheus metrics are automatically scraped by Alloy.

Ensure your application has:
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

### Application Logs

Logs from stdout/stderr are automatically collected by Alloy.

For structured logging, use JSON format:
```json
{"level":"info","msg":"Request processed","traceID":"abc123","duration":0.5}
```

### Application Traces

#### OpenTelemetry (Recommended)

Configure your application to send traces to Alloy:

```yaml
# Environment variables
OTEL_EXPORTER_OTLP_ENDPOINT: http://alloy.monitoring-stack.svc.cluster.local:4318
OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
```

#### Jaeger

For Jaeger-instrumented applications:

```yaml
JAEGER_AGENT_HOST: tempo-distributor.monitoring-stack.svc.cluster.local
JAEGER_AGENT_PORT: 6831
```

#### Zipkin

For Zipkin-instrumented applications:

```yaml
ZIPKIN_ENDPOINT: http://tempo-distributor.monitoring-stack.svc.cluster.local:9411
```

## Usage

### Accessing Grafana

1. Navigate to `https://grafana.techcasa.io`
2. Log in with admin credentials
3. Explore pre-configured data sources and dashboards

### Querying Logs (LogQL)

In Grafana → Explore → Select Loki:

```logql
# All logs from a namespace
{namespace="default"}

# Error logs
{namespace="default"} |= "error"

# Logs with trace ID extraction
{namespace="default"} | regexp "traceID=(?P<trace_id>\\w+)"

# Rate of errors
rate({namespace="default"} |= "error" [5m])
```

### Querying Traces (TraceQL)

In Grafana → Explore → Select Tempo:

```traceql
# Find traces with errors
{ status = error }

# Slow traces
{ duration > 1s }

# Traces for a specific service
{ service.name = "my-service" }

# Combined query
{ service.name = "my-service" && duration > 500ms }
```

### Correlating Data

Grafana automatically links:
- **Traces → Logs**: Click on a span to see related logs
- **Logs → Traces**: Click on a trace ID to see the full trace
- **Traces → Metrics**: See RED metrics for traced services

## Dashboards

Pre-installed dashboards:

1. **Kubernetes Cluster Monitoring** (ID: 7249)
   - Overview of cluster resources
   - Node utilization
   - Pod metrics

2. **Node Exporter** (ID: 1860)
   - Detailed node metrics
   - CPU, memory, disk, network

3. **Loki Logs** (ID: 13639)
   - Log volume and rates
   - Top log producers

4. **Tempo Traces** (ID: 16971)
   - Trace statistics
   - Service dependencies
   - Latency percentiles

### Creating Custom Dashboards

1. In Grafana, click **+** → **Dashboard**
2. Add panels with queries from multiple data sources
3. Use variables for dynamic filtering
4. Save and share with team

## Troubleshooting

### Check Deployment Status

```bash
kubectl get pods -n monitoring-stack
kubectl get svc -n monitoring-stack
kubectl get pvc -n monitoring-stack
```

### View Logs

```bash
# Loki
kubectl logs -n monitoring-stack -l app.kubernetes.io/name=loki -f

# Tempo
kubectl logs -n monitoring-stack -l app.kubernetes.io/name=tempo -f

# Alloy
kubectl logs -n monitoring-stack -l app.kubernetes.io/name=alloy -f

# Grafana
kubectl logs -n monitoring-stack -l app.kubernetes.io/name=grafana -f
```

### Test Data Sources

#### Loki

```bash
kubectl port-forward -n monitoring-stack svc/loki-gateway 3100:80
curl http://localhost:3100/loki/api/v1/labels
```

#### Tempo

```bash
kubectl port-forward -n monitoring-stack svc/tempo-query-frontend 3100:3100
curl http://localhost:3100/api/search
```

#### Alloy

```bash
kubectl port-forward -n monitoring-stack svc/alloy 12345:12345
curl http://localhost:12345/metrics
```

### Common Issues

**Issue**: Pods stuck in Pending
- **Solution**: Check PVC provisioning: `kubectl get pvc -n monitoring-stack`

**Issue**: Grafana data sources not working
- **Solution**: Verify service names and ports match the configuration

**Issue**: No logs appearing in Loki
- **Solution**: Check Alloy is running and configured correctly

**Issue**: No traces in Tempo
- **Solution**: Verify application is sending traces to correct endpoint

## Scaling

### Horizontal Scaling

Increase replicas in `helm/values.yaml`:

```yaml
# Loki
read:
  replicas: 3  # Increase from 2
write:
  replicas: 3

# Tempo
distributor:
  replicas: 3
ingester:
  replicas: 3
```

### Vertical Scaling

Increase resources:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi
```

## Security

### Secrets Management

Store sensitive values in Kubernetes secrets:

```bash
kubectl create secret generic grafana-credentials \
  --namespace monitoring-stack \
  --from-literal=admin-password=your-secure-password
```

Reference in Helm values:

```yaml
envFromSecret: grafana-credentials
```

### Network Policies

Apply network policies to restrict traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: monitoring-stack
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector: {}
```

## Maintenance

### Upgrading

```bash
# Update Helm repositories
helm repo update

# Upgrade individual components
cd loki && ./deploy.sh
cd tempo && ./deploy.sh
cd alloy && ./deploy.sh
cd grafana && ./deploy.sh
```

### Backup

Backup Grafana dashboards and data sources:

```bash
# Export dashboards
kubectl port-forward -n monitoring-stack svc/grafana 3000:80
# Use Grafana API or UI to export dashboards

# Backup PVCs
kubectl get pvc -n monitoring-stack
# Use your backup solution to snapshot volumes
```

### Monitoring the Monitors

All components expose Prometheus metrics via ServiceMonitors.

Check in Grafana → Prometheus data source:

```promql
# Loki ingestion rate
sum(rate(loki_distributor_bytes_received_total[5m]))

# Tempo ingestion rate
sum(rate(tempo_distributor_spans_received_total[5m]))

# Alloy health
up{job="alloy"}
```

## Integration with Existing Prometheus

This stack integrates with the existing Prometheus from `kube-prometheus-stack`:

- Alloy forwards metrics to Prometheus
- Grafana queries Prometheus for metrics
- Tempo generates metrics from traces → sent to Prometheus
- All components expose their own metrics via ServiceMonitors

## Cost Optimization

### Object Storage

For production and cost savings, use object storage instead of local volumes:

**Loki** - Use S3/GCS/Azure:
```yaml
loki:
  storage:
    type: s3
    bucketNames:
      chunks: loki-chunks
      ruler: loki-ruler
```

**Tempo** - Use S3/GCS/Azure:
```yaml
tempo:
  storage:
    trace:
      backend: s3
```

### Retention Tuning

Reduce retention periods to save storage:

```yaml
# Loki: 7 days instead of 31
retention_period: 168h

# Tempo: 7 days instead of 30
max_age: 168h
```

## References

- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
