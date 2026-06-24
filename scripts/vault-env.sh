#!/bin/bash
set -e

VAULT_ADDR=${VAULT_ADDR:-http://192.168.10.2:8200}
VAULT_TOKEN=${VAULT_TOKEN:?VAULT_TOKEN environment variable is required}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../docker/.env"

get() {
  docker exec vault vault kv get -field=$2 secret/$1
}

echo "==> Reading secrets from Vault..."

cat > "$ENV_FILE" << ENVEOF
# Auto-generated from Vault - do not edit manually
DOMAIN=duoowatch.com

# --- Databases ---
POSTGRES_USER=$(get databases postgres_user)
POSTGRES_PASSWORD=$(get databases postgres_password)
POSTGRES_DB=$(get databases postgres_db)
MONGO_INITDB_ROOT_USERNAME=$(get databases mongo_user)
MONGO_INITDB_ROOT_PASSWORD=$(get databases mongo_password)
REDIS_PASSWORD=$(get databases redis_password)

# --- Keycloak ---
KEYCLOAK_ADMIN_USER=$(get keycloak admin_user)
KEYCLOAK_ADMIN_PASSWORD=$(get keycloak admin_password)

# --- Grafana ---
GF_SECURITY_ADMIN_USER=$(get grafana admin_user)
GF_SECURITY_ADMIN_PASSWORD=$(get grafana admin_password)
KEYCLOAK_CLIENT_SECRET_GRAFANA=$(get grafana keycloak_client_secret)

# --- MinIO ---
MINIO_ROOT_USER=$(get minio root_user)
MINIO_ROOT_PASSWORD=$(get minio root_password)
KEYCLOAK_CLIENT_SECRET_MINIO=$(get minio keycloak_client_secret)

# --- Jellyfin ---
KEYCLOAK_CLIENT_SECRET_JELLYFIN=$(get jellyfin keycloak_client_secret)

# --- Misc ---
WATCHTOWER_SLACK_WEBHOOK=
VAULT_DEV_ROOT_TOKEN_ID=
ENVEOF

echo "==> .env generated at $ENV_FILE"
