#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check_reachable() {
  local label="$1"
  local container="$2"
  local target_host="$3"
  local target_port="$4"

  if docker exec "$container" sh -c "nc -z -w3 $target_host $target_port" 2>/dev/null; then
    printf "  [PASS] %-35s reachable\n" "$label"
    ((PASS++))
  else
    printf "  [FAIL] %-35s unreachable\n" "$label"
    ((FAIL++))
  fi
}

check_blocked() {
  local label="$1"
  local container="$2"
  local target_host="$3"
  local target_port="$4"

  if docker exec "$container" sh -c "nc -z -w2 $target_host $target_port" 2>/dev/null; then
    printf "  [FAIL] %-35s EXPOSED (should be blocked)\n" "$label"
    ((FAIL++))
  else
    printf "  [PASS] %-35s blocked\n" "$label"
    ((PASS++))
  fi
}

echo "========================================"
echo " Network Segmentation Test"
echo "========================================"
echo ""

echo "--- Internal service connectivity ---"
check_reachable "Traefik → Keycloak:8080"    traefik   keycloak  8080
check_reachable "Traefik → Grafana:3000"     traefik   grafana   3000
check_reachable "Keycloak → Postgres:5432"   keycloak  postgres  5432
check_reachable "Grafana → Prometheus:9090"  grafana   prometheus 9090
check_reachable "Grafana → Loki:3100"        grafana   loki      3100
check_reachable "MinIO → MinIO:9000"         minio     localhost 9000

echo ""
echo "--- Internet exposure (should be blocked from internal containers) ---"
check_blocked "postgres:5432 not on streaming-net"  traefik  postgres  5432
check_blocked "vault:8200 not on streaming-net"     traefik  vault     8200

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
