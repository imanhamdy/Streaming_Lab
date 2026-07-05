#!/bin/bash
set -e

VAULT_TOKEN=${VAULT_TOKEN:?VAULT_TOKEN environment variable is required}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

get() {
  docker exec -e VAULT_TOKEN="$VAULT_TOKEN" vault vault kv get -field="$2" secret/"$1"
}

echo "==> Reading secrets from Vault..."

cat > "$ENV_FILE" << ENVEOF
# Auto-generated from Vault — do not edit manually
DOMAIN=duoowatch.com
DOCKER_API_VERSION=1.41

# --- Databases ---
POSTGRES_USER=$(get databases postgres_user)
POSTGRES_PASSWORD=$(get databases postgres_password)
POSTGRES_DB=$(get databases postgres_db)
POSTGRES_REPLICATION_PASSWORD=$(get databases postgres_replication_password)

# --- Keycloak ---
KEYCLOAK_ADMIN=$(get keycloak admin_user)
KEYCLOAK_ADMIN_PASSWORD=$(get keycloak admin_password)
KC_DB_PASSWORD=$(get keycloak db_password)

# --- Grafana ---
GF_SECURITY_ADMIN_USER=$(get grafana admin_user)
GF_SECURITY_ADMIN_PASSWORD=$(get grafana admin_password)
GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=$(get grafana keycloak_client_secret)

# --- MinIO ---
MINIO_ROOT_USER=$(get minio root_user)
MINIO_ROOT_PASSWORD=$(get minio root_password)
KEYCLOAK_CLIENT_SECRET_MINIO=$(get minio keycloak_client_secret)
MINIO_IDENTITY_OPENID_CLIENT_SECRET=$(get minio keycloak_client_secret)

# --- Jellyfin ---
KEYCLOAK_CLIENT_SECRET_JELLYFIN=$(get jellyfin keycloak_client_secret)

# --- TrivyHub ---
TRIVYHUB_JWT_SECRET=$(get trivyhub jwt_secret)

# --- Traefik ---
TRAEFIK_DASHBOARD_USERS=$(get traefik dashboard_users)
ENVEOF

echo "==> .env written to $ENV_FILE"
