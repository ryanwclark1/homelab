#!/usr/bin/env bash
# Generate strong secrets for homelab infrastructure
# Creates encrypted vault files with random passwords

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Homelab Secret Generation                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check for vault password
if [ ! -f ~/.ansible-vault-pass ]; then
    echo -e "${BLUE}ℹ${NC} Creating vault password file..."
    openssl rand -base64 32 > ~/.ansible-vault-pass
    chmod 600 ~/.ansible-vault-pass
    echo -e "${GREEN}✓${NC} Vault password created: ~/.ansible-vault-pass"
    echo "  IMPORTANT: Back this up securely!"
    echo ""
fi

# Generate secrets
echo -e "${BLUE}ℹ${NC} Generating secrets..."
echo ""

# K3s cluster token
K3S_TOKEN=$(openssl rand -base64 48)
echo -e "${GREEN}✓${NC} K3s cluster token generated"

# Database passwords
POSTGRES_PASS=$(openssl rand -base64 32)
MYSQL_PASS=$(openssl rand -base64 32)
REDIS_PASS=$(openssl rand -base64 32)
echo -e "${GREEN}✓${NC} Database passwords generated"

# Application passwords
GRAFANA_PASS=$(openssl rand -base64 24)
MINIO_PASS=$(openssl rand -base64 24)
echo -e "${GREEN}✓${NC} Application passwords generated"

# Backup encryption key
BACKUP_KEY=$(openssl rand -base64 32)
echo -e "${GREEN}✓${NC} Backup encryption key generated"

# Create vault file for K3s
cat > /tmp/k3s-vault.yml <<EOF
---
# K3s cluster secrets
# Generated: $(date)

# K3s cluster token
vault_k3s_token: "$K3S_TOKEN"

# Database passwords
vault_postgres_password: "$POSTGRES_PASS"
vault_mysql_root_password: "$MYSQL_PASS"
vault_redis_password: "$REDIS_PASS"

# Application passwords
vault_grafana_admin_password: "$GRAFANA_PASS"
vault_minio_root_password: "$MINIO_PASS"

# Backup encryption
vault_backup_encryption_key: "$BACKUP_KEY"
EOF

# Encrypt and move
ansible-vault encrypt /tmp/k3s-vault.yml --vault-password-file ~/.ansible-vault-pass
mkdir -p group_vars/k3s_cluster
mv /tmp/k3s-vault.yml group_vars/k3s_cluster/vault.yml

echo ""
echo -e "${GREEN}✓${NC} Secrets encrypted and saved to: group_vars/k3s_cluster/vault.yml"
echo ""

# Display next steps
echo "Next steps:"
echo "  1. Back up ~/.ansible-vault-pass securely"
echo "  2. Review secrets: ansible-vault view group_vars/k3s_cluster/vault.yml"
echo "  3. Generate Proxmox/TrueNAS secrets if needed"
echo "  4. Never commit vault password to git!"
echo ""

# Save passwords to secure location (optional)
read -p "Save plaintext passwords to temporary file for reference? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TEMP_FILE="/tmp/homelab-secrets-$(date +%Y%m%d-%H%M%S).txt"
    cat > "$TEMP_FILE" <<EOF
Homelab Generated Secrets - $(date)
KEEP THIS FILE SECURE AND DELETE AFTER COPYING TO PASSWORD MANAGER!

K3s Cluster Token:
$K3S_TOKEN

PostgreSQL Password:
$POSTGRES_PASS

MySQL Root Password:
$MYSQL_PASS

Redis Password:
$REDIS_PASS

Grafana Admin Password:
$GRAFANA_PASS

MinIO Root Password:
$MINIO_PASS

Backup Encryption Key:
$BACKUP_KEY

Vault Password Location:
~/.ansible-vault-pass

IMPORTANT:
1. Copy these to your password manager
2. Delete this file: rm $TEMP_FILE
3. Never commit to git!
EOF

    chmod 600 "$TEMP_FILE"
    echo ""
    echo -e "${GREEN}✓${NC} Plaintext secrets saved to: $TEMP_FILE"
    echo "  Copy to password manager, then: rm $TEMP_FILE"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Secret Generation Complete                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
