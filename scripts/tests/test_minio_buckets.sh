#!/usr/bin/env bash
set -euo pipefail

source /home/principal/streaming-lab/.env

echo "[$(date)] Creating and verifying MinIO buckets..."
docker run --rm \
  --network streaming-net \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc mb -p minio/backups || true && \
         mc mb -p minio/db-dumps || true && \
         mc mb -p minio/streaming-media || true && \
         mc ls minio"

echo "[$(date)] Bucket check: OK"
