# Homelab Docker Compose Setup

A simplified, secure, and maintainable Docker Compose configuration for running a comprehensive homelab.

## Quick Start

```bash
# List all stacks
./manage-stacks.sh list

# Start a stack
./manage-stacks.sh start arr

# View logs
./manage-stacks.sh logs arr --follow

# Update a stack
./manage-stacks.sh update arr
```

## Stacks

- **arr**: Media management (Radarr, Sonarr, Lidarr, etc.)
- **monitoring**: Prometheus, Grafana, Loki
- **network**: Traefik reverse proxy
- **n8n**: Workflow automation
- **semaphore**: Ansible UI
- **atuin**: Shell history
- **immich**: Photo management

## Management Script

The `manage-stacks.sh` script provides easy management:

```bash
./manage-stacks.sh [COMMAND] [STACK] [OPTIONS]

Commands:
  list          List all stacks
  status        Show stack status
  start         Start stack
  stop          Stop stack
  restart       Restart stack
  logs          View logs
  pull          Pull latest images
  update        Pull and restart
  config        Validate configuration
  ps            List containers
  down          Stop and remove
```

## Security

✅ No hardcoded credentials
✅ Automated database backups
✅ Security headers (HSTS, XSS, etc.)
✅ Health checks for all databases
✅ SSL/TLS via Traefik

## Documentation

- [SIMPLIFICATION_CHANGELOG.md](SIMPLIFICATION_CHANGELOG.md) - Complete changelog
- [POSTGRESQL_ANALYSIS.md](POSTGRESQL_ANALYSIS.md) - Database analysis
- [test-compose.sh](test-compose.sh) - Automated testing

## Setup

1. Configure secrets:
```bash
mkdir -p secrets
echo "your-token" > secrets/cf_dns_api_token
```

2. Setup standalone apps:
```bash
cd n8n && cp .env.sample .env && nano .env
cd ../semaphore && cp .env.sample .env && nano .env
```

3. Start stacks:
```bash
./manage-stacks.sh start network
./manage-stacks.sh start arr
```

## Testing

```bash
./test-compose.sh
```

---

**Last Updated**: 2025-11-08
