#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"
ENV_FILE="$DOCKER_DIR/.env"

STACKS="databases proxy keycloak security storage jellyfin monitoring"

if [ -n "$1" ]; then
  STACKS="$1"
fi

for stack in $STACKS; do
  echo "==> Restarting $stack..."
  docker compose --env-file "$ENV_FILE" -f "$DOCKER_DIR/$stack/docker-compose.yml" restart
done

echo ""
docker ps --format "table {{.Names}}\t{{.Status}}"
