# Asterisk Monitoring

This directory contains Kubernetes manifests for monitoring Asterisk instances using Prometheus and Grafana.

## Components

- **PrometheusRule**: Alert rules for Asterisk metrics
- **ServiceMonitor**: Prometheus scrape configuration for Asterisk metrics endpoints
- **Namespace**: Dedicated namespace for Asterisk monitoring resources

## Deployment

### Using kubectl

```bash
kubectl apply -k manifests/
```

### Using kustomize

```bash
kustomize build manifests/ | kubectl apply -f -
```

## Alerts

The following alerts are configured:

- **AsteriskRestarted**: Critical alert when Asterisk restarts
- **AsteriskReloaded**: Warning when Asterisk configuration is reloaded
- **AsteriskHighScrapeTime**: Critical alert for slow metric scraping (>100ms)
- **AsteriskHighActiveCallsCount**: Warning when active calls exceed 100

## Grafana Dashboards

Pre-built Grafana dashboards are available in the `vendor/` directory:
- `asterisk-overview.json`: Overview dashboard with key metrics
- `asterisk-logs.json`: Log analysis dashboard

### Importing Dashboards

1. Access Grafana UI
2. Navigate to Dashboards → Import
3. Upload the JSON files from `vendor/github.com/grafana/jsonnet-libs/asterisk-mixin/dashboards/`

## Metrics

Asterisk metrics are expected to be exposed in Prometheus format on the `/metrics` endpoint.

Key metrics include:
- `asterisk_core_uptime_seconds`: Asterisk uptime
- `asterisk_core_last_reload_seconds`: Time since last reload
- `asterisk_core_scrape_time_ms`: Metric scrape duration
- `asterisk_calls_count`: Active call count

## Configuration

Update the ServiceMonitor selector to match your Asterisk service labels:

```yaml
spec:
  selector:
    matchLabels:
      app: asterisk  # Change to match your service
```
