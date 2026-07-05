#!/bin/bash
set -e

# Runs once on cluster bootstrap (primary only).
# Creates per-service DB users and databases.

export PGHOST=/data/patroni

psql -U "${POSTGRES_USER}" -d postgres <<-EOSQL
    CREATE DATABASE keycloak;
    CREATE USER keycloak WITH PASSWORD '${KC_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
EOSQL

psql -U "${POSTGRES_USER}" -d keycloak <<-EOSQL
    GRANT ALL ON SCHEMA public TO keycloak;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO keycloak;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO keycloak;
EOSQL

echo "post_bootstrap: keycloak DB and user configured"
