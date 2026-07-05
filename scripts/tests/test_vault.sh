#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

ok()   { printf "  [PASS] %s\n" "$1"; ((PASS++)); }
fail() { printf "  [FAIL] %s\n" "$1"; ((FAIL++)); }

echo "========================================"
echo " Vault Health Test"
echo "========================================"
echo ""

# Health endpoint (no token needed)
HEALTH=$(curl -s "http://192.168.10.2:8200/v1/sys/health" 2>/dev/null || echo "{}")

INITIALIZED=$(echo "$HEALTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('initialized',''))" 2>/dev/null || echo "false")
SEALED=$(echo "$HEALTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sealed',''))" 2>/dev/null || echo "true")

if [ "$INITIALIZED" = "True" ] || [ "$INITIALIZED" = "true" ]; then
  ok "Vault initialized"
else
  fail "Vault not initialized"
fi

if [ "$SEALED" = "False" ] || [ "$SEALED" = "false" ]; then
  ok "Vault unsealed"
else
  fail "Vault is sealed — secrets unavailable"
fi

# Test .env generation if VAULT_TOKEN is set
if [ -n "${VAULT_TOKEN:-}" ]; then
  echo ""
  echo "--- Secret access (VAULT_TOKEN set) ---"
  RESULT=$(docker exec -e VAULT_TOKEN="$VAULT_TOKEN" vault vault kv get -field=root_user secret/minio 2>/dev/null || echo "")
  if [ -n "$RESULT" ]; then
    ok "MinIO secret readable from Vault"
  else
    fail "Cannot read secret/minio from Vault"
  fi
else
  echo "  [SKIP] VAULT_TOKEN not set — skipping secret read test"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
