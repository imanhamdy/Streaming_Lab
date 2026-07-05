#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

ok()   { printf "  [PASS] %s\n" "$1"; ((PASS++)); }
fail() { printf "  [FAIL] %s\n" "$1"; ((FAIL++)); }

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
TARGETS=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null | \
  python3 -c "import sys,json; d=json.load(sys.stdin); \
    [print(t['labels'].get('job','?'), t['health']) for t in d['data']['activeTargets']]" 2>/dev/null || echo "")

if [ -n "$TARGETS" ]; then
  UP=$(echo "$TARGETS" | grep -c "up" || true)
  DOWN=$(echo "$TARGETS" | grep -c "down" || true)
  ok "Prometheus targets: $UP up, $DOWN down"
  if [ "$DOWN" -gt 0 ]; then
    echo "     DOWN targets:"
    echo "$TARGETS" | grep "down" | while read -r line; do echo "       $line"; done
    ((FAIL++)); ((PASS--))
  fi
else
  fail "Could not reach Prometheus API"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
