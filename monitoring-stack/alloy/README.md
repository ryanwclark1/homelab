# Grafana Alloy

Grafana Alloy is the next-generation telemetry collector that replaces Grafana Agent. It collects metrics, logs, and traces from your Kubernetes cluster.

## Features

- **Multi-signal collection**: Metrics, logs, and traces in one agent
- **Flow configuration**: Modern, declarative configuration language
- **High availability**: Clustering support for reliable operation
- **Kubernetes-native**: Automatic service discovery
- **Efficient**: Lower resource usage than traditional agents

## Configuration

The Alloy configuration (`helm/values.yaml`) is written in Flow language and includes:

### Metrics Collection

```flow
prometheus.scrape "kubernetes_pods" {
  targets = discovery.kubernetes.pods.targets
  forward_to = [prometheus.remote_write.default.receiver]
}
```

### Log Collection

```flow
loki.source.kubernetes "pods" {
  targets = discovery.kubernetes.pods.targets
  forward_to = [loki.write.default.receiver]
}
```

### Trace Collection

```flow
otelcol.receiver.otlp "default" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }
  output { traces = [otelcol.exporter.otlp.tempo.input] }
}
```

## Deployment

```bash
./deploy.sh
```

## Instrumentation Examples

See `manifests/example-instrumented-app.yaml` for a complete example of how to instrument applications.

### Metrics

Applications should expose Prometheus metrics on `/metrics`:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Logs

Write structured JSON logs to stdout:

```json
{
  "level": "info",
  "msg": "Request processed",
  "traceID": "abc123",
  "method": "GET",
  "path": "/api/users",
  "duration": 0.5
}
```

### Traces

Configure OpenTelemetry SDK:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy.monitoring-stack.svc.cluster.local:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

## Verification

Check Alloy is collecting data:

```bash
# Port-forward to Alloy
kubectl port-forward -n monitoring-stack svc/alloy 12345:12345

# Check metrics
curl http://localhost:12345/metrics
```

## Troubleshooting

View Alloy logs:

```bash
kubectl logs -n monitoring-stack -l app.kubernetes.io/name=alloy -f
```

Common issues:

- **No data in Loki**: Check Loki endpoint is reachable
- **No traces in Tempo**: Verify Tempo distributor endpoint
- **High memory usage**: Reduce scrape targets or increase limits
