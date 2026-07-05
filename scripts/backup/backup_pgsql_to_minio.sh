#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="/tmp/streaming-lab-db-dumps"
BUCKET="db-dumps"

source /home/principal/streaming-lab/.env

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting PostgreSQL dump via Patroni primary (haproxy-postgres:5000)..."
# Connect through HAProxy port 5000 which always points to the current primary
docker run --rm \
  --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" \
  -v "$BACKUP_DIR:/backup" \
  postgres:17-alpine \
  pg_dumpall -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -f "/backup/postgres_all_$DATE.sql"

gzip "$BACKUP_DIR/postgres_all_$DATE.sql"
echo "[$(date)] Dump compressed: postgres_all_$DATE.sql.gz"

echo "[$(date)] Uploading to MinIO bucket: $BUCKET..."
docker run --rm \
  --network streaming-private \
  -v "$BACKUP_DIR:/backup" \
  --entrypoint /bin/sh minio/mc:latest \
  -c "mc alias set minio http://minio:9000 \"$MINIO_ROOT_USER\" \"$MINIO_ROOT_PASSWORD\" && \
      mc mb -p minio/$BUCKET && \
      mc cp /backup/postgres_all_$DATE.sql.gz minio/$BUCKET/"

rm -rf "$BACKUP_DIR"
echo "[$(date)] Done. Backup uploaded to minio/$BUCKET/postgres_all_$DATE.sql.gz"
