#!/usr/bin/env bash
set -euo pipefail

source /home/principal/streaming-lab/.env

PASS=0
FAIL=0

ok()   { printf "  [PASS] %s\n" "$1"; ((PASS++)); }
fail() { printf "  [FAIL] %s\n" "$1"; ((FAIL++)); }

echo "========================================"
echo " PostgreSQL Backup Validation"
echo "========================================"
echo ""

# 1. Run backup
echo "[1/4] Running backup script..."
if bash /home/principal/streaming-lab/scripts/backup/backup_pgsql_to_minio.sh; then
  ok "Backup script exited successfully"
else
  fail "Backup script failed"
  exit 1
fi

# 2. Verify dump exists in MinIO
echo ""
echo "[2/4] Checking dump in MinIO bucket db-dumps..."
LATEST=$(docker run --rm \
  --network streaming-net \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc ls minio/db-dumps" 2>/dev/null | awk '{print $NF}' | sort | tail -1)

if [ -n "$LATEST" ]; then
  ok "Latest dump in MinIO: $LATEST"
else
  fail "No dump found in MinIO bucket db-dumps"
  exit 1
fi

# 3. Download and test readability
echo ""
echo "[3/4] Downloading and testing dump readability..."
mkdir -p /tmp/backup-test-$$
docker run --rm \
  --network streaming-net \
  -v /tmp/backup-test-$$:/restore \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc cp minio/db-dumps/$LATEST /restore/" 2>/dev/null

DUMP_FILE="/tmp/backup-test-$$/$LATEST"
if gunzip -t "$DUMP_FILE" 2>/dev/null; then
  ok "Dump archive integrity: OK"
else
  fail "Dump archive is corrupt"
  rm -rf /tmp/backup-test-$$
  exit 1
fi

FIRST_LINE=$(gunzip -c "$DUMP_FILE" | head -n1)
if echo "$FIRST_LINE" | grep -q "PostgreSQL database cluster dump"; then
  ok "Dump content valid (pg_dumpall format)"
else
  fail "Unexpected dump content: $FIRST_LINE"
fi

# 4. Cleanup
rm -rf /tmp/backup-test-$$

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
