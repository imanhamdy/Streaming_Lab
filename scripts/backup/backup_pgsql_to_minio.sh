#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="/tmp/streaming-lab-db-dumps"
BUCKET="db-dumps"

source /home/principal/streaming-lab/.env

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting PostgreSQL dump (via haproxy-postgres leader:5000)..."
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  pg_dumpall -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" \
  | gzip > "$BACKUP_DIR/postgres_all_$DATE.sql.gz"
echo "[$(date)] Dump compressed: postgres_all_$DATE.sql.gz"

echo "[$(date)] Uploading to MinIO bucket: $BUCKET..."
docker run --rm \
  --network streaming-public \
  -v "$BACKUP_DIR:/backup" \
  --entrypoint /bin/sh minio/mc:latest \
  -c "mc alias set minio http://minio:9000 \"$MINIO_ROOT_USER\" \"$MINIO_ROOT_PASSWORD\" && \
      mc mb -p minio/$BUCKET && \
      mc cp /backup/postgres_all_$DATE.sql.gz minio/$BUCKET/"

echo "[$(date)] Done. Backup uploaded to minio/$BUCKET/postgres_all_$DATE.sql.gz"
echo "[$(date)] Local copy kept at: $BACKUP_DIR/postgres_all_$DATE.sql.gz"
