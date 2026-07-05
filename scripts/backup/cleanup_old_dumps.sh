#!/usr/bin/env bash
set -euo pipefail

source /home/principal/streaming-lab/.env

RETENTION_DAYS="${RETENTION_DAYS:-30}"
BUCKET="db-dumps"

echo "[$(date)] Cleaning dumps older than $RETENTION_DAYS days from minio/$BUCKET..."

docker run --rm \
  --network streaming-private \
  --entrypoint /bin/sh minio/mc:latest \
  -c "mc alias set minio http://minio:9000 \"$MINIO_ROOT_USER\" \"$MINIO_ROOT_PASSWORD\" && \
      mc rm --recursive --force --older-than ${RETENTION_DAYS}d minio/$BUCKET/ || true"

echo "[$(date)] Cleanup done."
