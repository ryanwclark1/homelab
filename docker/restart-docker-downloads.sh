# /usr/local/bin/restart-docker-downloads.sh
#!/usr/bin/env bash
set -euo pipefail

cd ~/homelab/docker
docker compose -f docker-compose-arr.yml --profile downloads restart