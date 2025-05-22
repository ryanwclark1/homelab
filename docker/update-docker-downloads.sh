# /usr/local/bin/update-docker-downloads.sh
#!/usr/bin/env bash
set -euo pipefail

cd ~/homelab/docker
docker compose -f docker-compose-arr.yml --profile downloads pull
docker compose -f docker-compose-arr.yml --profile downloads up -d
docker image prune -af --filter "until=168h"  # remove images unused in past 7 days
docker container prune -f
docker volume prune -f
