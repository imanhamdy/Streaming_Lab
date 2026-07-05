#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local name="$1"
  if docker inspect "$name" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    printf "  [PASS] %-25s running\n" "$name"
    ((PASS++))
  else
    printf "  [FAIL] %-25s not running\n" "$name"
    ((FAIL++))
  fi
}

echo "========================================"
echo " Container Status Check"
echo "========================================"
echo ""

# Proxy
check traefik

# Auth / IAM
check keycloak
check vault

# Database HA cluster
check etcd
check postgres-01
check postgres-02
check haproxy-postgres

# Storage
check minio

# Media
check jellyfin
check jellyfin-rclone

# Monitoring
check grafana
check prometheus
check loki
check promtail
check alertmanager
check cadvisor
check node-exporter
check trivyhub

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
