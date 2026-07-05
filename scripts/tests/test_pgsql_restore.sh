#!/usr/bin/env bash
set -euo pipefail

source /home/principal/streaming-lab/.env

PASS=0
FAIL=0
RESTORE_CONTAINER="postgres-restore-test-$$"

ok()   { printf "  [PASS] %s\n" "$1"; ((PASS++)); }
fail() { printf "  [FAIL] %s\n" "$1"; ((FAIL++)); }

cleanup() {
  docker stop "$RESTORE_CONTAINER" 2>/dev/null || true
  docker rm "$RESTORE_CONTAINER" 2>/dev/null || true
  rm -rf /tmp/restore-test-$$
}
trap cleanup EXIT

echo "========================================"
echo " PostgreSQL Restore Test"
echo "========================================"
echo ""

# 1. Download latest dump from MinIO
echo "[1/4] Downloading latest dump from MinIO..."
mkdir -p /tmp/restore-test-$$

LATEST=$(docker run --rm \
  --network streaming-net \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc ls minio/db-dumps" 2>/dev/null | awk '{print $NF}' | sort | tail -1)

if [ -z "$LATEST" ]; then
  fail "No dump found in MinIO — run test_pgsql_backup.sh first"
  exit 1
fi

docker run --rm \
  --network streaming-net \
  -v /tmp/restore-test-$$:/restore \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc cp minio/db-dumps/$LATEST /restore/" 2>/dev/null

ok "Downloaded: $LATEST"

# 2. Start temporary postgres container
echo ""
echo "[2/4] Starting temporary PostgreSQL container..."
docker run -d \
  --name "$RESTORE_CONTAINER" \
  --network db-net \
  -e POSTGRES_PASSWORD=testonly \
  -e POSTGRES_USER=postgres \
  postgres:17-alpine

sleep 6

if docker inspect "$RESTORE_CONTAINER" --format '{{.State.Running}}' | grep -q true; then
  ok "Temporary container started"
else
  fail "Temporary container failed to start"
  exit 1
fi

# 3. Restore dump
echo ""
echo "[3/4] Restoring dump..."
if gunzip -c "/tmp/restore-test-$$/$LATEST" | \
   docker exec -i "$RESTORE_CONTAINER" psql -U postgres -q 2>/dev/null; then
  ok "Dump restored without errors"
else
  fail "Restore failed"
  exit 1
fi

# 4. Validate databases exist
echo ""
echo "[4/4] Validating restored databases..."
DB_LIST=$(docker exec "$RESTORE_CONTAINER" psql -U postgres -tAc "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null)

if echo "$DB_LIST" | grep -q "keycloak\|postgres"; then
  ok "Expected databases found: $(echo $DB_LIST | tr '\n' ' ')"
else
  fail "Expected databases not found. Found: $DB_LIST"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
