#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0

run_test() {
  local num="$1"
  local label="$2"
  local script="$3"

  ((TOTAL++))
  printf "\n%02d %-20s " "$num" "$label"

  if bash "$SCRIPT_DIR/$script" &>/tmp/test_output_$$; then
    printf "[PASS]\n"
    ((PASS++))
  else
    printf "[FAIL]\n"
    sed 's/^/     /' /tmp/test_output_$$ | grep -E "FAIL|error|Error" | head -5 || true
    ((FAIL++))
  fi
}

echo ""
echo "========================================"
echo " Streaming Lab — Full Test Suite"
echo " $(date)"
echo "========================================"

run_test  1  "Containers"     "test_containers.sh"
run_test  2  "Networks"       "test_network.sh"
run_test  3  "Routes"         "test_routes.sh"
run_test  4  "Volumes"        "test_volumes.sh"
run_test  5  "MinIO buckets"  "test_minio_buckets.sh"
run_test  6  "PG Backup"      "test_pgsql_backup.sh"
run_test  7  "PG Restore"     "test_pgsql_restore.sh"
run_test  8  "Monitoring"     "test_monitoring.sh"
run_test  9  "SSO"            "test_sso.sh"
run_test 10  "Vault"          "test_vault.sh"
run_test 11  "Backup repo"    "test_backup_repository.sh"

rm -f /tmp/test_output_$$

echo ""
echo "========================================"
printf " OVERALL: %d/%d PASS\n" "$PASS" "$TOTAL"
echo "========================================"
echo ""

[ "$FAIL" -eq 0 ]
