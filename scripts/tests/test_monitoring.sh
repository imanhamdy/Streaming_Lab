#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

ok()   { printf "  [PASS] %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }

http_ok() {
  local label="$1"
  local url="$2"
  local expected="${3:-200}"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
  if [ "$status" = "$expected" ] || [[ "$status" =~ ^(200|204|301|302)$ && "$expected" = "2xx" ]]; then
    ok "$label → HTTP $status"
  else
    fail "$label → HTTP $status (expected $expected)"
  fi
}

echo "========================================"
echo " Monitoring Stack Test"
echo "========================================"
echo ""

echo "--- Endpoints ---"
http_ok "Prometheus health"   "http://localhost:9090/-/healthy"
http_ok "Prometheus ready"    "http://localhost:9090/-/ready"
http_ok "Grafana health"      "http://localhost:3000/api/health"
http_ok "Loki ready"          "http://localhost:3100/ready"
http_ok "Alertmanager health" "http://localhost:9093/-/healthy"

echo ""
echo "--- Prometheus targets ---"
# node-vm-dns (192.168.20.2) is a separate lab VM not always deployed — expected down
EXPECTED_DOWN="node-vm-dns"

TARGETS=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null | \
  python3 -c "import sys,json; d=json.load(sys.stdin); \
    [print(t['labels'].get('job','?'), t['health']) for t in d['data']['activeTargets']]" 2>/dev/null || echo "")

if [ -n "$TARGETS" ]; then
  UP=$(echo "$TARGETS" | grep -c " up" || true)
  UNEXPECTED_DOWN=$(echo "$TARGETS" | grep " down" | grep -v "$EXPECTED_DOWN" || true)
  DOWN_COUNT=$(echo "$TARGETS" | grep -c " down" || true)
  ok "Prometheus targets: $UP up, $DOWN_COUNT down"
  if [ -n "$UNEXPECTED_DOWN" ]; then
    echo "     UNEXPECTED DOWN targets:"
    echo "$UNEXPECTED_DOWN" | while read -r line; do echo "       $line"; done
    FAIL=$((FAIL+1)); PASS=$((PASS-1))
  else
    echo "     (node-vm-dns expected down — separate VM)"
  fi
else
  fail "Could not reach Prometheus API"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
