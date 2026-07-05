#!/usr/bin/env bash
set -euo pipefail

DOMAINS=(
  "jellyfin.duoowatch.com"
  "grafana.duoowatch.com"
  "keycloak.duoowatch.com"
  "minio.duoowatch.com"
  "vault.duoowatch.com"
  "trivyhub.duoowatch.com"
)

PASS=0
FAIL=0

for d in "${DOMAINS[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1" -H "Host: $d" || echo "000")
  if [[ "$STATUS" =~ ^(200|301|302|307|308)$ ]]; then
    echo "  OK  $d → HTTP $STATUS"
    ((PASS++))
  else
    echo " FAIL $d → HTTP $STATUS"
    ((FAIL++))
  fi
done

echo ""
echo "Results: $PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
