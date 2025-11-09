# K3s Cluster Management Guide

Complete guide for deploying and managing your K3s cluster with Ansible.

## Overview

This Ansible setup deploys and manages:
- **6 Master nodes** (HA control plane)
- **5 Worker nodes** (workload execution)
- **3 Storage nodes** (Longhorn storage)
- **14 total nodes** across 6 Proxmox hosts

## Architecture

```
k3s-node01 (james)     - Master (bootstrap)
k3s-node02 (andrew)    - Master
k3s-node03 (john)      - Master
k3s-node04 (peter)     - Master
k3s-node05 (judas)     - Master
k3s-node06 (philip)    - Master

k3s-node07-14          - Workers (8 nodes)
k3s-storage17-19       - Storage (3 nodes with 200GB disks)

Cluster VIP: 10.10.101.50
MetalLB Range: 10.10.101.60-100
```

## Prerequisites

1. **VMs created** via Terraform
   ```bash
   cd terraform && ./deploy.sh all
   ```

2. **Collections installed**
   ```bash
   cd ansible && make install-collections
   ```

3. **Cluster token** (generate strong token)
   ```bash
   openssl rand -base64 32
   ```

## Quick Start

### 1. Configure Cluster Token

Create vault file:
```bash
ansible-vault create group_vars/k3s_cluster/vault.yml
```

Add token:
```yaml
vault_k3s_token: "your-generated-token-here"
```

### 2. Deploy Cluster

```bash
# Full deployment
make k3s-deploy

# Or step-by-step
ansible-playbook -i inventories/k3s/hosts.yml playbooks/k3s-deploy.yml
```

Deployment order:
1. First master (k3s-node01) - bootstrap
2. Additional masters - join cluster
3. Workers - join as agents
4. Storage nodes - configure Longhorn

### 3. Get Kubeconfig

```bash
make k3s-kubeconfig

# Use kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes
```

### 4. Verify Cluster

```bash
make k3s-health

# Or manually
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

## Configuration

Key variables in `inventories/k3s/hosts.yml`:

```yaml
vars:
  k3s_version: v1.28.8+k3s1
  k3s_cluster_vip: 10.10.101.50
  k3s_cluster_cidr: 10.42.0.0/16
  k3s_service_cidr: 10.43.0.0/16

  metallb_enabled: true
  metallb_ip_range: 10.10.101.60-10.10.101.100

  longhorn_enabled: true
  traefik_enabled: true
```

## Cluster Features

### High Availability
- 6 master nodes with embedded etcd
- Cluster VIP for API access
- Automatic leader election

### Load Balancing
- MetalLB for LoadBalancer services
- IP range: 10.10.101.60-100

### Storage
- Longhorn distributed storage
- 3 dedicated storage nodes
- 200GB per storage node

### Networking
- Flannel CNI (VXLAN backend)
- Custom cluster/service CIDRs
- Network policies support

## Operations

### Deploy Applications

```bash
# Example: Deploy nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get LoadBalancer IP
kubectl get svc nginx
```

### Scale Workers

1. Add VM in Terraform
2. Update `inventories/k3s/hosts.yml`
3. Run playbook:
   ```bash
   ansible-playbook -i inventories/k3s/hosts.yml \
     playbooks/k3s-deploy.yml \
     --limit new-worker-node
   ```

### Upgrade Cluster

1. Update `k3s_version` in inventory
2. Run upgrade:
   ```bash
   ansible-playbook -i inventories/k3s/hosts.yml \
     playbooks/k3s-upgrade.yml
   ```

### Drain and Remove Node

```bash
# Drain node
kubectl drain k3s-node14 --ignore-daemonsets --delete-emptydir-data

# Delete from cluster
kubectl delete node k3s-node14

# Remove K3s from node
ansible k3s-node14 -i inventories/k3s/hosts.yml \
  -m shell -a "/usr/local/bin/k3s-uninstall.sh" -b
```

## Integration

### With Docker Compose

Deploy applications to K3s instead of Docker:

```bash
# Instead of docker-compose up
kubectl apply -f k8s-manifests/

# Or use Helm
helm install myapp ./charts/myapp
```

### With TrueNAS

Use TrueNAS NFS for persistent volumes:

```yaml
# StorageClass for TrueNAS NFS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: truenas-nfs
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.10.100.50
  share: /mnt/tank/k3s-pv
```

### With Prometheus

K3s metrics available at:
- Master nodes: `https://<node-ip>:6443/metrics`
- Kubelet: `http://<node-ip>:10250/metrics`

## Troubleshooting

### Cluster Not Starting

```bash
# Check K3s service
ansible k3s_masters -i inventories/k3s/hosts.yml \
  -m systemd -a "name=k3s state=status" -b

# View logs
ansible k3s-node01 -i inventories/k3s/hosts.yml \
  -m command -a "journalctl -u k3s -n 100" -b
```

### Nodes Not Ready

```bash
# Check node status
kubectl describe node k3s-node01

# Check CNI
kubectl get pods -n kube-system | grep flannel

# Restart K3s
ansible k3s-node01 -i inventories/k3s/hosts.yml \
  -m systemd -a "name=k3s state=restarted" -b
```

### Storage Issues

```bash
# Check Longhorn
kubectl get pods -n longhorn-system

# Check PVCs
kubectl get pvc --all-namespaces

# Longhorn UI
kubectl port-forward -n longhorn-system \
  svc/longhorn-frontend 8080:80
```

## Best Practices

1. **Use Namespaces** - Organize applications
2. **Resource Limits** - Set CPU/memory limits
3. **Health Checks** - Configure liveness/readiness probes
4. **Labels** - Tag resources for organization
5. **Secrets** - Use Kubernetes secrets, not ConfigMaps
6. **Backups** - Regular etcd and PV backups
7. **Monitoring** - Deploy Prometheus/Grafana
8. **GitOps** - Use Flux or ArgoCD

## References

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Longhorn](https://longhorn.io/)
- [MetalLB](https://metallb.universe.tf/)
- [Traefik](https://doc.traefik.io/traefik/)

## Summary

**Complete K3s Stack:**
- ✅ 14-node highly available cluster
- ✅ Distributed storage (Longhorn)
- ✅ Load balancing (MetalLB)
- ✅ Ingress controller (Traefik)
- ✅ Automated deployment
- ✅ Health monitoring
- ✅ Integrated with Terraform & Ansible

Use `make k3s-deploy` to get started!
