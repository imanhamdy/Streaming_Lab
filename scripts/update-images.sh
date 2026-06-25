#!/bin/bash
# Update Docker image versions to fix CVEs identified by TrivyHub

set -e

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker" && pwd)"

echo "Updating image versions to fix CVEs..."

# Databases
sed -i 's|image: postgres:15-alpine|image: postgres:17-alpine|g' "$DOCKER_DIR/databases/docker-compose.yml"
sed -i 's|image: mongo:4.4|image: mongo:8.0.10|g' "$DOCKER_DIR/databases/docker-compose.yml"

# Jellyfin
sed -i 's|image: jellyfin/jellyfin$|image: jellyfin/jellyfin:10.10.7|g' "$DOCKER_DIR/jellyfin/docker-compose.yml"

# Keycloak
sed -i 's|image: quay.io/keycloak/keycloak:24.0|image: quay.io/keycloak/keycloak:26.2.5|g' "$DOCKER_DIR/keycloak/docker-compose.yml"

# Traefik
sed -i 's|image: traefik:v3.0|image: traefik:v3.4.1|g' "$DOCKER_DIR/proxy/docker-compose.yml"

# Vault
sed -i 's|image: hashicorp/vault:1.17|image: hashicorp/vault:1.19.3|g' "$DOCKER_DIR/security/docker-compose.yml"

# MinIO
sed -i 's|image: minio/minio:latest|image: minio/minio:RELEASE.2025-06-13T11-33-47Z|g' "$DOCKER_DIR/storage/docker-compose.yml"

# Monitoring stack
sed -i 's|image: prom/prometheus:v2.51.0|image: prom/prometheus:v3.4.1|g' "$DOCKER_DIR/monitoring/docker-compose.yml"
sed -i 's|image: grafana/loki:3.0.0|image: grafana/loki:3.4.3|g' "$DOCKER_DIR/monitoring/docker-compose.yml"
sed -i 's|image: grafana/promtail:3.0.0|image: grafana/promtail:3.4.3|g' "$DOCKER_DIR/monitoring/docker-compose.yml"
sed -i 's|image: grafana/grafana:11.0.0|image: grafana/grafana:11.6.1|g' "$DOCKER_DIR/monitoring/docker-compose.yml"
sed -i 's|image: containrrr/watchtower:latest|image: containrrr/watchtower:1.7.1|g' "$DOCKER_DIR/monitoring/docker-compose.yml"

echo "Done. Versions updated:"
echo "  postgres:15-alpine       -> postgres:17-alpine"
echo "  mongo:4.4                -> mongo:8.0.10"
echo "  jellyfin/jellyfin        -> jellyfin/jellyfin:10.10.7"
echo "  keycloak:24.0            -> keycloak:26.2.5"
echo "  traefik:v3.0             -> traefik:v3.4.1"
echo "  vault:1.17               -> vault:1.19.3"
echo "  minio:latest             -> minio:RELEASE.2025-06-13T11-33-47Z"
echo "  prometheus:v2.51.0       -> prometheus:v3.4.1"
echo "  loki:3.0.0               -> loki:3.4.3"
echo "  promtail:3.0.0           -> promtail:3.4.3"
echo "  grafana:11.0.0           -> grafana:11.6.1"
echo "  watchtower:latest        -> watchtower:1.7.1"
echo ""
echo "Run 'docker compose up -d' for each service to apply changes."
