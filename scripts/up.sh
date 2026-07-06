#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"
ENV_FILE="$DOCKER_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Copy .env.example and fill in values."
  exit 1
fi

dc() {
  docker compose --env-file "$ENV_FILE" -f "$DOCKER_DIR/$1/docker-compose.yml" up -d --remove-orphans
}

echo "==> Creating networks..."
for net in streaming-public streaming-private streaming-monitoring; do
  docker network inspect "$net" >/dev/null 2>&1 || docker network create "$net"
done

echo "==> Starting databases..."
dc databases

echo "==> Starting proxy..."
dc proxy

echo "==> Starting keycloak..."
dc keycloak

echo "==> Starting vault..."
dc security

echo "==> Starting storage..."
dc storage

echo "==> Starting jellyfin..."
dc jellyfin

echo "==> Starting monitoring..."
dc monitoring

echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
