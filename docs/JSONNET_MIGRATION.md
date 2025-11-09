# Jsonnet to Standard Kubernetes YAML Migration

This document describes the migration from jsonnet-based configuration to standard Kubernetes YAML manifests.

## Overview

The homelab infrastructure has been migrated from jsonnet to standard Kubernetes YAML and Helm charts for better maintainability and simpler deployment workflows.

## What Changed

### Before: Jsonnet-based Workflow

```bash
# Install dependencies
jb init
jb install <package>

# Generate manifests
jsonnet -J vendor -m manifests monitoring.jsonnet | gojsontoyaml

# Complex build process
./build.sh
```

**Drawbacks:**
- Required multiple tools (jsonnet, jsonnet-bundler, gojsontoyaml)
- Complex build scripts
- Build step needed before deployment
- Harder to debug and understand
- Limited IDE support

### After: Standard YAML/Helm Workflow

```bash
# Kubernetes monitoring
./deploy-helm.sh

# Flux system
kubectl apply -k base/flux-system/manifests/

# Asterisk monitoring
kubectl apply -k monitoring/asterisk/manifests/
```

**Benefits:**
- Standard Kubernetes YAML
- Native kubectl/kustomize support
- Helm for complex stacks
- No build step required
- Better IDE support and validation
- Easier to understand and modify

## Migration Details

### 1. Flux System Configuration

**Location:** `base/flux-system/`

**Old:** `jsonnet/main.jsonnet` → generated YAML files

**New:** `manifests/*.yaml` - Direct YAML manifests

**Resources:**
- NetworkPolicy for cert-manager
- Ingress for webhook receiver
- PrometheusRule for monitoring
- PodMonitor for metrics
- ExternalSecrets for credentials
- Provider, Alert, Receiver for notifications

**Deployment:**
```bash
kubectl apply -k base/flux-system/manifests/
```

### 2. Kubernetes Monitoring Stack

**Location:** `kubernetes/monitoring/`

**Old:** `monitoring.jsonnet` + kube-prometheus library

**New:** Helm chart + YAML manifests

**Changes:**
- Uses official `kube-prometheus-stack` Helm chart
- Configuration in `values.yaml`
- IngressRoutes in `manifests/`

**Deployment:**
```bash
./deploy-helm.sh
```

Or using Ansible:
```bash
cd ansible
make k3s-monitoring
```

### 3. Asterisk Monitoring

**Location:** `monitoring/asterisk/`

**Old:** `asterisk-metrics.jsonnet` → generated JSON

**New:** `manifests/*.yaml` - Direct YAML manifests

**Resources:**
- PrometheusRule with alert definitions
- ServiceMonitor for metric scraping
- Namespace configuration

**Deployment:**
```bash
kubectl apply -k monitoring/asterisk/manifests/
```

## File Status

### Deprecated Files

These files are **no longer used** but kept for reference:

- `base/flux-system/jsonnet/main.jsonnet`
- `kubernetes/monitoring/monitoring.jsonnet`
- `kubernetes/monitoring/build.sh`
- `kubernetes/monitoring/setup.sh`
- `monitoring/asterisk/asterisk-metrics.jsonnet`
- `Makefile.common` (jsonnet targets)

### Active Files

These are the **current** configuration files:

- `base/flux-system/manifests/*.yaml`
- `kubernetes/monitoring/values.yaml`
- `kubernetes/monitoring/manifests/*.yaml`
- `kubernetes/monitoring/deploy-helm.sh`
- `monitoring/asterisk/manifests/*.yaml`

## Updating Configurations

### Flux System

Edit YAML files directly in `base/flux-system/manifests/`:

```bash
# Update Slack channel
vim base/flux-system/manifests/provider-slack.yaml

# Apply changes
kubectl apply -k base/flux-system/manifests/
```

### Monitoring Stack

Update Helm values:

```bash
# Edit configuration
vim kubernetes/monitoring/values.yaml

# Apply changes
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values kubernetes/monitoring/values.yaml
```

Update IngressRoutes:

```bash
# Edit routes
vim kubernetes/monitoring/manifests/ingressroute-*.yaml

# Apply changes
kubectl apply -k kubernetes/monitoring/manifests/
```

### Asterisk Monitoring

Edit YAML files directly:

```bash
# Update alert thresholds
vim monitoring/asterisk/manifests/prometheusrule.yaml

# Apply changes
kubectl apply -k monitoring/asterisk/manifests/
```

## Cleanup (Optional)

To remove deprecated jsonnet files:

```bash
# Backup first!
git checkout -b cleanup-jsonnet

# Remove jsonnet directories
rm -rf base/flux-system/jsonnet
rm -rf monitoring/asterisk/vendor
rm -rf monitoring/asterisk/*.jsonnet
rm -rf kubernetes/monitoring/*.jsonnet
rm -rf kubernetes/monitoring/jsonnetfile.*
rm -rf kubernetes/monitoring/vendor

# Remove old build scripts
rm -f kubernetes/monitoring/build.sh
rm -f kubernetes/monitoring/setup.sh

# Remove generated files
rm -f monitoring/asterisk/generated.json

# Commit
git add -A
git commit -m "Remove deprecated jsonnet configuration"
```

## Makefile Updates

The `Makefile.common` file contains jsonnet-specific targets that are **deprecated**:

- `make fmt` - Format jsonnet code
- `make generate` - Generate YAML from jsonnet
- `make update` - Update jsonnet dependencies

These targets are kept for backward compatibility but are not used in the new workflow.

### Main Makefile

The main `Makefile` has been updated to exclude jsonnet directories from scanning:

```makefile
--not -path "*/jsonnet/*" --not -path "*/vendor/*"
```

## CI/CD Considerations

If you have CI/CD pipelines that use jsonnet:

1. **Remove jsonnet installation** from CI setup
2. **Remove build steps** (no manifest generation needed)
3. **Update validation** to use kubectl/kustomize directly
4. **Update deployment** to use kubectl apply -k or helm

Example GitHub Actions before:

```yaml
- name: Install jsonnet
  run: |
    go install github.com/google/go-jsonnet/cmd/jsonnet@latest
    go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest

- name: Generate manifests
  run: make generate
```

Example GitHub Actions after:

```yaml
- name: Validate manifests
  run: |
    kubectl apply --dry-run=client -k base/flux-system/manifests/
    kubectl apply --dry-run=client -k monitoring/asterisk/manifests/
```

## Troubleshooting

### "Command 'jsonnet' not found"

This is expected if you're trying to use deprecated jsonnet commands. Use the new YAML-based workflow instead.

### IngressRoute not working

Ensure Traefik CRDs are installed:

```bash
kubectl get crd ingressroutes.traefik.io
```

### Helm chart not found

Add the Prometheus community repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Further Reading

- [Flux System README](../base/flux-system/README.md)
- [Kubernetes Monitoring README](../kubernetes/monitoring/README.md)
- [Asterisk Monitoring README](../monitoring/asterisk/README.md)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Helm Documentation](https://helm.sh/docs/)
