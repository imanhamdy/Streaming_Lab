#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

# Use bash /dev/tcp as universal TCP probe (works in all containers that have bash)
# Falls back to nc for containers that have it instead of bash
tcp_check() {
  local container="$1" host="$2" port="$3"
  # Suppress all output; rely on exit code only
  docker exec "$container" bash -c "timeout 3 bash -c 'echo > /dev/tcp/$host/$port'" &>/dev/null \
    || docker exec "$container" sh -c "nc -z -w3 $host $port" &>/dev/null
}

check_reachable() {
  local label="$1" container="$2" host="$3" port="$4"
  if tcp_check "$container" "$host" "$port"; then
    printf "  [PASS] %-40s reachable\n" "$label"
    PASS=$((PASS+1))
  else
    printf "  [FAIL] %-40s unreachable\n" "$label"
    FAIL=$((FAIL+1))
  fi
}

check_blocked() {
  local label="$1" container="$2" host="$3" port="$4"
  if tcp_check "$container" "$host" "$port"; then
    printf "  [FAIL] %-40s EXPOSED (should be blocked)\n" "$label"
    FAIL=$((FAIL+1))
  else
    printf "  [PASS] %-40s blocked\n" "$label"
    PASS=$((PASS+1))
  fi
}

echo "========================================"
echo " Network Segmentation Test"
echo "========================================"
echo ""

echo "--- Internal service connectivity (streaming-public) ---"
check_reachable "Traefik → Keycloak:8080"       traefik    keycloak    8080
check_reachable "Traefik → Grafana:3000"        traefik    grafana     3000
check_reachable "Grafana → Prometheus:9090"     grafana    prometheus  9090
check_reachable "Grafana → Loki:3100"           grafana    loki        3100

echo ""
echo "--- Internal service connectivity (streaming-private) ---"
check_reachable "HAProxy → postgres-01:5432"    haproxy-postgres  postgres-01  5432
check_reachable "HAProxy → postgres-02:5432"    haproxy-postgres  postgres-02  5432

echo ""
echo "--- Isolation: streaming-private not reachable from streaming-public ---"
check_blocked "postgres-01:5432 blocked from traefik"  traefik  postgres-01  5432
check_blocked "etcd:2379 blocked from traefik"         traefik  etcd         2379

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
