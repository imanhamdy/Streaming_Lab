#!/bin/bash
set -e

# Create dedicated DB users per service.
# POSTGRES_USER (superuser) is only used for admin/init — never by app services.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    -- Keycloak gets its own role on its own database
    CREATE USER keycloak WITH PASSWORD '${KC_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
EOSQL

# Grant schema-level privileges once connected to the keycloak DB
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "keycloak" <<-EOSQL
    GRANT ALL ON SCHEMA public TO keycloak;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO keycloak;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO keycloak;
EOSQL
