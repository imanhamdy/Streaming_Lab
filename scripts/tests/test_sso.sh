#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

ok()   { printf "  [PASS] %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }

echo "========================================"
echo " SSO / Keycloak Test"
echo "========================================"
echo ""

REALM="streaming-lab"
KC_BASE="https://keycloak.duoowatch.com/realms/$REALM"

# 1. Discovery document
echo "--- OIDC discovery ---"
ISSUER=$(curl -s "$KC_BASE/.well-known/openid-configuration" 2>/dev/null | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('issuer',''))" 2>/dev/null || echo "")

if [ "$ISSUER" = "$KC_BASE" ]; then
  ok "Keycloak OIDC discovery: issuer matches ($ISSUER)"
else
  fail "Keycloak OIDC discovery failed or issuer mismatch. Got: $ISSUER"
fi

# 2. MinIO SSO redirect
echo ""
echo "--- Service SSO endpoints ---"
MINIO_LOGIN=$(curl -s -H "Host: minio.duoowatch.com" http://127.0.0.1/api/v1/login 2>/dev/null || echo "{}")
STRATEGY=$(echo "$MINIO_LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('loginStrategy',''))" 2>/dev/null || echo "")

if [ "$STRATEGY" = "redirect" ]; then
  ok "MinIO SSO: loginStrategy=redirect (Keycloak SSO active)"
elif [ "$STRATEGY" = "form" ]; then
  fail "MinIO SSO: loginStrategy=form (SSO not active)"
else
  fail "MinIO SSO: unexpected response"
fi

# 3. Grafana OAuth
GRAFANA_HEALTH=$(curl -s "http://localhost:3000/api/health" 2>/dev/null | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('database',''))" 2>/dev/null || echo "")

if [ "$GRAFANA_HEALTH" = "ok" ]; then
  ok "Grafana reachable (database: ok)"
else
  fail "Grafana health check failed"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
