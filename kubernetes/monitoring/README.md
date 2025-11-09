# Monitoring Stack

This directory contains the Kubernetes monitoring stack based on kube-prometheus.

## Manifests

The manifests in this directory are pre-generated Kubernetes YAML files that deploy:
- Prometheus
- Grafana
- Alertmanager
- Node Exporter
- Kube State Metrics
- Blackbox Exporter
- Prometheus Adapter

## Customizations

For information about customizing the monitoring stack, see:
https://github.com/prometheus-operator/kube-prometheus/tree/main/docs/customizations

## Structure

- `manifests/` - Pre-generated Kubernetes manifests
- `manifests/setup/` - CRDs and initial setup resources (apply these first)
