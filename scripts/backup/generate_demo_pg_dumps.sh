#!/usr/bin/env bash
set -euo pipefail

source /home/principal/streaming-lab/.env

BUCKET="db-dumps"
TMP="/tmp/demo-pg-dumps"
mkdir -p "$TMP"

echo "Generating 6 demo pg_dumps → MinIO bucket '$BUCKET'"
echo ""

docker exec minio mc alias set local http://localhost:9000 \
  "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" --quiet 2>/dev/null || true

for DATE in 2026-07-01 2026-07-02 2026-07-03 2026-07-04 2026-07-05 2026-07-06; do
  FILENAME="postgres_all_${DATE}_023000.sql.gz"
  LOCAL="$TMP/$FILENAME"

  printf "  %-45s " "$FILENAME"

  # pg_dump runs on postgres-01 (has the binary), dumps keycloak DB
  docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" postgres-01 \
    pg_dump -h localhost -p 5432 -U "$POSTGRES_USER" "$POSTGRES_DB" \
    2>/dev/null | gzip > "$LOCAL"

  SIZE=$(du -sh "$LOCAL" | cut -f1)

  docker cp "$LOCAL" "minio:/tmp/$FILENAME"
  docker exec minio mc cp "/tmp/$FILENAME" "local/$BUCKET/$FILENAME" --quiet 2>/dev/null

  echo "✓  $SIZE"
done

echo ""
echo "Bucket contents:"
docker exec minio mc ls "local/$BUCKET/"
