---
# Secrets Management Guide for Homelab Infrastructure

## Overview

This guide covers secure management of sensitive data across:
- Proxmox API credentials
- TrueNAS API keys
- K3s cluster tokens
- Database passwords
- SSH keys
- TLS certificates

## Ansible Vault

### Setup

1. **Create vault password file**

```bash
# Generate strong password
openssl rand -base64 32 > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass
```

2. **Configure Ansible to use it**

```ini
# ansible/ansible.cfg
[defaults]
vault_password_file = ~/.ansible-vault-pass
```

### Creating Vault Files

**For Proxmox hosts:**
```bash
cd ansible
ansible-vault create group_vars/proxmox_cluster/vault.yml
```

Add content:
```yaml
---
# Proxmox secrets
vault_proxmox_api_token_id: "root@pam!terraform"
vault_proxmox_api_token_secret: "your-secret-here"

# Backup encryption
vault_backup_encryption_key: "another-secret"
```

**For TrueNAS:**
```bash
ansible-vault create group_vars/truenas_servers/vault.yml
```

```yaml
---
# TrueNAS API key
vault_truenas_api_key: "1-abc123def456..."

# SMB passwords
vault_truenas_smb_admin_password: "secure-password"
```

**For K3s:**
```bash
ansible-vault create group_vars/k3s_cluster/vault.yml
```

```yaml
---
# K3s cluster token
vault_k3s_token: "K10abcdef1234567890abcdef1234567890abcdef1234567890"

# Docker registry credentials
vault_docker_registry_password: "registry-pass"

# Database passwords
vault_postgres_password: "db-password"
vault_mysql_root_password: "mysql-root-pass"
```

### Using Vault Variables

Reference vault variables in regular vars:

```yaml
# group_vars/k3s_cluster/main.yml
k3s_token: "{{ vault_k3s_token }}"
docker_registry_password: "{{ vault_docker_registry_password }}"
```

### Vault Commands

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit group_vars/k3s_cluster/vault.yml

# View encrypted file
ansible-vault view group_vars/k3s_cluster/vault.yml

# Encrypt existing file
ansible-vault encrypt plaintext-secrets.yml

# Decrypt file
ansible-vault decrypt group_vars/k3s_cluster/vault.yml

# Rekey (change password)
ansible-vault rekey group_vars/k3s_cluster/vault.yml
```

## Terraform Secrets

### Option 1: Environment Variables

```bash
# terraform/.env (add to .gitignore!)
export TF_VAR_proxmox_api_token_secret="your-secret"
export TF_VAR_truenas_api_key="your-key"

# Source before running Terraform
source .env
terraform plan
```

### Option 2: terraform.tfvars (Encrypted)

```bash
cd terraform/proxmox

# Create tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Encrypt with Ansible Vault
ansible-vault encrypt terraform.tfvars

# Use with Terraform
ansible-vault view terraform.tfvars | terraform apply -var-file=/dev/stdin
```

### Option 3: External Secrets Manager

Use HashiCorp Vault, AWS Secrets Manager, or similar:

```hcl
# terraform/proxmox/secrets.tf
data "vault_generic_secret" "proxmox" {
  path = "secret/proxmox"
}

locals {
  proxmox_api_token_secret = data.vault_generic_secret.proxmox.data["api_token_secret"]
}
```

## SSH Keys

### Generate Keys

```bash
# For Proxmox access
ssh-keygen -t ed25519 -C "proxmox-automation" -f ~/.ssh/homelab_proxmox

# For K3s nodes
ssh-keygen -t ed25519 -C "k3s-nodes" -f ~/.ssh/homelab_k3s

# Set permissions
chmod 600 ~/.ssh/homelab_*
chmod 644 ~/.ssh/homelab_*.pub
```

### Distribute Keys

```bash
# To Proxmox hosts
for host in james andrew john peter judas philip; do
  ssh-copy-id -i ~/.ssh/homelab_proxmox.pub root@$host.techcasa.io
done

# Via Ansible
ansible proxmox_cluster -m authorized_key \
  -a "user=root key='{{ lookup('file', '~/.ssh/homelab_proxmox.pub') }}' state=present"
```

### Configure SSH Agent

```bash
# ~/.ssh/config
Host *.techcasa.io
    IdentityFile ~/.ssh/homelab_proxmox
    User root

Host 10.10.101.*
    IdentityFile ~/.ssh/homelab_k3s
    User administrator
```

## Generating Strong Secrets

### Random Passwords

```bash
# Strong password
openssl rand -base64 32

# Hex token
openssl rand -hex 32

# Alphanumeric
tr -dc A-Za-z0-9 </dev/urandom | head -c 32

# K3s cluster token
openssl rand -base64 48
```

### Automated Secret Generation

```bash
# ansible/scripts/generate-secrets.sh
#!/usr/bin/env bash

echo "Generating secrets..."

# K3s token
K3S_TOKEN=$(openssl rand -base64 48)

# Database passwords
POSTGRES_PASS=$(openssl rand -base64 32)
MYSQL_PASS=$(openssl rand -base64 32)

# Create vault file
cat > /tmp/generated-secrets.yml <<EOF
---
vault_k3s_token: "$K3S_TOKEN"
vault_postgres_password: "$POSTGRES_PASS"
vault_mysql_root_password: "$MYSQL_PASS"
EOF

# Encrypt
ansible-vault encrypt /tmp/generated-secrets.yml
mv /tmp/generated-secrets.yml ansible/group_vars/k3s_cluster/vault.yml

echo "✓ Secrets generated and encrypted"
```

## Kubernetes Secrets

### External Secrets Operator

Deploy to automatically sync from vault:

```yaml
# kubernetes/external-secrets/
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.techcasa.io"
      path: "secret"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

### Sealed Secrets

Encrypt secrets for Git:

```bash
# Install kubeseal
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create sealed secret
kubectl create secret generic mysecret \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > mysealedsecret.yaml

# Commit sealed secret to Git
git add mysealedsecret.yaml
```

## Secret Rotation

### Rotation Schedule

```yaml
# Recommended rotation periods
SSH Keys: Annually
API Tokens: Every 90 days
Passwords: Every 90 days
TLS Certs: Auto-renewed (Let's Encrypt)
K3s Token: Annually or on compromise
```

### Rotation Process

```bash
# 1. Generate new secret
NEW_TOKEN=$(openssl rand -base64 48)

# 2. Update vault
ansible-vault edit group_vars/k3s_cluster/vault.yml
# Change vault_k3s_token value

# 3. Update cluster (rolling)
ansible-playbook playbooks/rotate-k3s-token.yml

# 4. Verify
ansible-playbook playbooks/k3s-health.yml
```

## Best Practices

### DO ✅

- **Use Ansible Vault** for all secrets
- **Generate strong secrets** (32+ characters)
- **Rotate regularly** (90 day cycle)
- **Use separate credentials** per service
- **Limit vault password** access (need-to-know)
- **Backup encrypted** vault files
- **Use SSH keys** over passwords
- **Enable MFA** where possible
- **Audit access** regularly
- **Document secret** locations

### DON'T ❌

- **Commit plaintext secrets** to Git
- **Reuse passwords** across services
- **Share vault password** insecurely
- **Use weak passwords** ("password123")
- **Store secrets** in code comments
- **Email secrets** (use secure sharing)
- **Use default credentials**
- **Disable encryption** for convenience
- **Skip rotation**
- **Ignore failed login** alerts

## Emergency Procedures

### Compromised Secret

```bash
# 1. Revoke immediately
# For API token:
pveum user token remove root@pam terraform

# 2. Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# 3. Update vault
ansible-vault edit group_vars/proxmox_cluster/vault.yml

# 4. Redeploy
ansible-playbook playbooks/site.yml

# 5. Document incident
echo "$(date): Rotated proxmox API token due to compromise" >> docs/security-log.md
```

### Lost Vault Password

```bash
# If you have plaintext copy:
ansible-vault rekey group_vars/*/vault.yml

# If completely lost:
# You must recreate all secrets from scratch
# This is why backups are critical!
```

## Backup Strategy

### Encrypted Backups

```bash
# Backup all vault files
tar -czf vault-backup-$(date +%Y%m%d).tar.gz \
  ansible/group_vars/*/vault.yml

# Encrypt backup
gpg --symmetric --cipher-algo AES256 vault-backup-*.tar.gz

# Store securely offsite
# - Encrypted USB drive
# - Cloud storage (encrypted)
# - Password manager's secure notes
```

### Recovery Test

```bash
# Quarterly test:
# 1. Restore vault backup
# 2. Decrypt
# 3. Verify secrets work
# 4. Document results
```

## Audit Checklist

Monthly security review:

```markdown
- [ ] All secrets in vault (none in plaintext)
- [ ] Vault password secure and backed up
- [ ] No secrets in Git history
- [ ] SSH keys rotated per schedule
- [ ] API tokens reviewed and rotated
- [ ] Unused credentials removed
- [ ] Access logs reviewed
- [ ] Backup tested
- [ ] Team trained on procedures
- [ ] Documentation up to date
```

## Example Directory Structure

```
ansible/
├── group_vars/
│   ├── all/
│   │   ├── main.yml           # Public vars
│   │   └── vault.yml          # Encrypted secrets
│   ├── proxmox_cluster/
│   │   ├── main.yml
│   │   └── vault.yml          # Proxmox secrets
│   ├── truenas_servers/
│   │   ├── main.yml
│   │   └── vault.yml          # TrueNAS secrets
│   └── k3s_cluster/
│       ├── main.yml
│       └── vault.yml          # K3s secrets
│
├── .ansible-vault-pass        # Vault password (in .gitignore)
└── scripts/
    ├── generate-secrets.sh    # Secret generation
    └── rotate-secrets.sh      # Secret rotation
```

## References

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Terraform Sensitive Data](https://www.terraform.io/docs/language/values/variables.html#suppressing-values-in-cli-output)
- [External Secrets Operator](https://external-secrets.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [HashiCorp Vault](https://www.vaultproject.io/)

## Quick Reference

```bash
# Create vault file
ansible-vault create group_vars/k3s_cluster/vault.yml

# Edit vault file
ansible-vault edit group_vars/k3s_cluster/vault.yml

# View vault file
ansible-vault view group_vars/k3s_cluster/vault.yml

# Generate strong password
openssl rand -base64 32

# Run playbook with vault
ansible-playbook playbooks/site.yml --ask-vault-pass

# Or with password file
ansible-playbook playbooks/site.yml
```
