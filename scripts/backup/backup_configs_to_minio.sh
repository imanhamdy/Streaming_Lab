#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%Y-%m-%d_%H-%M-%S)"
TMP="/tmp/streaming-lab-configs-$DATE"
ARCHIVE="/tmp/streaming-lab-configs-$DATE.tar.gz"
BUCKET="backups"

source /home/principal/streaming-lab/.env

mkdir -p "$TMP"

echo "[$(date)] Collecting config files..."
rsync -a \
  --exclude=".env" \
  --exclude="*.key" \
  --exclude="*.pem" \
  --exclude="rclone.conf" \
  --exclude="node_modules" \
  ~/streaming-lab/docker \
  ~/streaming-lab/docs \
  ~/streaming-lab/scripts \
  "$TMP/"

tar -czf "$ARCHIVE" -C "$TMP" .
echo "[$(date)] Archive created: $ARCHIVE"

echo "[$(date)] Uploading to MinIO bucket: $BUCKET..."
docker run --rm \
  --network streaming-net \
  -v /tmp:/backup \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc mb -p minio/$BUCKET && \
         mc cp /backup/streaming-lab-configs-$DATE.tar.gz minio/$BUCKET/"

rm -rf "$TMP" "$ARCHIVE"
echo "[$(date)] Done. Config backup uploaded to minio/$BUCKET/streaming-lab-configs-$DATE.tar.gz"
