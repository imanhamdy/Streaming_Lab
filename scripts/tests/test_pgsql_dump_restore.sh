#!/usr/bin/env bash
set -euo pipefail

LATEST_DUMP="$(ls -t /tmp/streaming-lab-db-dumps/*.sql.gz 2>/dev/null | head -n1 || true)"

if [ -z "$LATEST_DUMP" ]; then
  echo "No local dump found. Run backup_pgsql_to_minio.sh first or download one from MinIO."
  exit 1
fi

echo "Testing dump: $LATEST_DUMP"
gunzip -c "$LATEST_DUMP" | head -n 20

echo ""
echo "Dump readable: OK"
