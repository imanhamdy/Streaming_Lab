#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local name="$1"
  if docker inspect "$name" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    printf "  [PASS] %-20s running\n" "$name"
    PASS=$((PASS+1))
  else
    printf "  [FAIL] %-20s not running\n" "$name"
    FAIL=$((FAIL+1))
  fi
}

echo "========================================"
echo " Container Status Check"
echo "========================================"
echo ""

check traefik
check keycloak
check postgres
check minio
check jellyfin
check jellyfin-rclone
check grafana
check prometheus
check loki
check promtail
check alertmanager
check cadvisor
check node-exporter
check vault
check trivyhub

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
