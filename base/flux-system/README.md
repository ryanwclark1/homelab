# Flux System Configuration

This directory contains Kubernetes manifests for configuring the Flux GitOps toolkit.

## Overview

Flux is deployed as a GitOps continuous delivery solution for Kubernetes. This configuration adds:
- Monitoring integration (Prometheus/Grafana)
- Notification system (Slack)
- Webhook receiver for GitHub
- Network policies
- Ingress for webhook access

## Components

### Monitoring

**PrometheusRule** (`prometheusrule.yaml`)
- Alert when Flux reconciliation fails for >20 minutes
- Integrated with cluster-wide Prometheus

**PodMonitor** (`podmonitor.yaml`)
- Scrapes metrics from all Flux controllers
- Drops unnecessary rest_client metrics to reduce cardinality

### Notifications

**Provider** (`provider-slack.yaml`)
- Slack notification provider
- Posts to `#deployments` channel
- Uses webhook URL from ExternalSecret

**Alert** (`alert.yaml`)
- Sends notifications for all GitRepository and Kustomization events
- Event severity: info (includes successful deployments)

**Receiver** (`receiver.yaml`)
- GitHub webhook receiver
- Triggers reconciliation on push events
- Validates requests with token from ExternalSecret

### Secrets

**ExternalSecret** (`externalsecret-github.yaml`)
- Fetches GitHub webhook token from Doppler
- Creates `github-webhook-token` Secret

**ExternalSecret** (`externalsecret-slack.yaml`)
- Fetches Slack webhook URL from Doppler
- Creates `slack-url` Secret

### Network

**NetworkPolicy** (`networkpolicy-cert-manager.yaml`)
- Allows cert-manager to reach ACME HTTP-01 challenge solvers
- Required for automatic TLS certificate provisioning

**Ingress** (`ingress.yaml`)
- Exposes webhook receiver at flux.techcasa.io
- Uses Traefik ingress controller
- Automatic TLS with cert-manager

## Deployment

### Apply Manifests

```bash
kubectl apply -k manifests/
```

### Using Flux

Add to your Flux Kustomization:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-config
  namespace: flux-system
spec:
  interval: 10m
  path: ./base/flux-system/manifests
  prune: true
  sourceRef:
    kind: GitRepository
    name: homelab
```

## Configuration

### Update Slack Channel

Edit `manifests/provider-slack.yaml`:

```yaml
spec:
  channel: your-channel-name  # Change from 'deployments'
```

### Update Webhook Repository

Edit `manifests/receiver.yaml`:

```yaml
spec:
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1beta1
      kind: GitRepository
      name: your-repo-name  # Change from 'homelab'
```

### Configure GitHub Webhook

1. Get the webhook URL:
   ```bash
   kubectl -n flux-system get receiver github-receiver -o jsonpath='{.status.webhookPath}'
   ```

2. In your GitHub repository:
   - Settings → Webhooks → Add webhook
   - Payload URL: `https://flux.techcasa.io/<webhook-path>`
   - Content type: `application/json`
   - Secret: Use the value from `FLUX_GITHUB_TOKEN` in Doppler
   - Events: Just the push event

## Secrets Management

This configuration expects secrets to be stored in Doppler and synchronized via External Secrets Operator.

### Required Secrets in Doppler

| Secret Key | Description |
|------------|-------------|
| `FLUX_GITHUB_TOKEN` | GitHub webhook secret token |
| `FLUX_SLACK_URL` | Slack incoming webhook URL |

### Manual Secret Creation

If not using External Secrets, create secrets manually:

```bash
# GitHub webhook token
kubectl create secret generic github-webhook-token \
  --namespace flux-system \
  --from-literal=token=<your-token>

# Slack webhook URL
kubectl create secret generic slack-url \
  --namespace flux-system \
  --from-literal=address=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Monitoring

### View Flux Metrics

```bash
kubectl port-forward -n flux-system svc/source-controller 8080:80
```

Visit http://localhost:8080/metrics

### Check Reconciliation Status

```bash
flux get all
```

### View Alerts in Prometheus

Query: `ALERTS{alertname="ReconciliationFailure"}`

## Troubleshooting

### Webhook Not Working

1. Check receiver status:
   ```bash
   kubectl describe receiver github-receiver -n flux-system
   ```

2. Verify ingress:
   ```bash
   kubectl get ingress -n flux-system
   ```

3. Check recent webhook deliveries in GitHub repo settings

### Slack Notifications Not Sending

1. Verify secret exists:
   ```bash
   kubectl get secret slack-url -n flux-system
   ```

2. Check provider status:
   ```bash
   kubectl describe provider slack -n flux-system
   ```

3. Verify alert is active:
   ```bash
   kubectl describe alert all-deployments -n flux-system
   ```

### Prometheus Not Scraping

1. Check PodMonitor:
   ```bash
   kubectl describe podmonitor flux-system -n flux-system
   ```

2. Verify service labels match PodMonitor selector:
   ```bash
   kubectl get pods -n flux-system --show-labels
   ```

## Migration from Jsonnet

This configuration replaces the previous jsonnet-based manifests with standard YAML.

**Benefits:**
- No build step required
- Standard Kubernetes YAML
- Easier to understand and modify
- Better IDE support and validation

The `jsonnet/` directory is kept for reference but is no longer used.
