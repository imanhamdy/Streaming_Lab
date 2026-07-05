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
    printf "  [PASS] %-40s reachable\n" "$label"
    ((PASS++))
  else
    printf "  [FAIL] %-40s unreachable\n" "$label"
    ((FAIL++))
  fi
}

check_blocked() {
  local label="$1"
  local container="$2"
  local target_host="$3"
  local target_port="$4"

  if docker exec "$container" sh -c "nc -z -w2 $target_host $target_port" 2>/dev/null; then
    printf "  [FAIL] %-40s EXPOSED (should be blocked)\n" "$label"
    ((FAIL++))
  else
    printf "  [PASS] %-40s blocked\n" "$label"
    ((PASS++))
  fi
}

echo "========================================"
echo " Network Segmentation Test"
echo "========================================"
echo ""

echo "--- streaming-public: Traefik-exposed services ---"
check_reachable "Traefik → Keycloak:8080"       traefik   keycloak       8080
check_reachable "Traefik → Grafana:3000"        traefik   grafana        3000
check_reachable "Traefik → MinIO console:9001"  traefik   minio          9001

echo ""
echo "--- streaming-private: database/storage reach ---"
check_reachable "Keycloak → HAProxy:5000"       keycloak  haproxy-postgres 5000
check_reachable "MinIO → HAProxy:5000"          minio     haproxy-postgres 5000

echo ""
echo "--- streaming-monitoring: metrics reach ---"
check_reachable "Grafana → Prometheus:9090"     grafana   prometheus     9090
check_reachable "Grafana → Loki:3100"           grafana   loki           3100

echo ""
echo "--- Isolation: postgres not reachable from Traefik (streaming-public) ---"
check_blocked "Traefik cannot reach postgres-01:5432"  traefik  postgres-01  5432
check_blocked "Traefik cannot reach postgres-02:5432"  traefik  postgres-02  5432
check_blocked "Traefik cannot reach etcd:2379"         traefik  etcd         2379

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
