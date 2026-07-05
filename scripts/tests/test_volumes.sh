#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check_volume() {
  local label="$1"
  local volume="$2"

  if docker volume inspect "$volume" &>/dev/null; then
    local mount
    mount=$(docker volume inspect "$volume" --format '{{.Mountpoint}}')
    if [ -d "$mount" ]; then
      printf "  [PASS] %-30s exists at %s\n" "$label" "$mount"
      ((PASS++))
    else
      printf "  [FAIL] %-30s volume exists but mountpoint missing\n" "$label"
      ((FAIL++))
    fi
  else
    printf "  [FAIL] %-30s volume not found\n" "$label"
    ((FAIL++))
  fi
}

check_rclone_mount() {
  local label="$1"
  local path="$2"

  if mountpoint -q "$path" 2>/dev/null; then
    printf "  [PASS] %-30s mounted\n" "$label"
    ((PASS++))
  elif [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null)" ]; then
    printf "  [PASS] %-30s accessible (non-empty)\n" "$label"
    ((PASS++))
  else
    printf "  [FAIL] %-30s not mounted or empty\n" "$label"
    ((FAIL++))
  fi
}

echo "========================================"
echo " Volume Persistence Check"
echo "========================================"
echo ""

check_volume "postgres_data"       "databases_postgres_data"
check_volume "minio_data"          "storage_minio_data"
check_volume "grafana_data"        "monitoring_grafana_data"
check_volume "loki_data"           "monitoring_loki_data"
check_volume "prometheus_data"     "monitoring_prometheus_data"

echo ""
echo "--- FUSE / rclone mounts ---"
check_rclone_mount "streaming-media (rclone)" "/home/principal/streaming-media"

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
