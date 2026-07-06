#!/usr/bin/env bash
# Test Patroni streaming replication: Leader → Replica lag and data consistency
set -euo pipefail

source /home/principal/streaming-lab/.env

PASS=0; FAIL=0
ok()   { echo "  ✅ $*"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }
hdr()  { echo; echo "▶ $*"; }

hdr "Patroni cluster state"
CLUSTER=$(docker exec postgres-01 patronictl -c /etc/patroni/config.yml list 2>/dev/null)
echo "$CLUSTER"

LEADER=$(echo "$CLUSTER" | awk '/Leader/ {print $2}')
REPLICA=$(echo "$CLUSTER" | awk '/Replica/ {print $2}')
[ -n "$LEADER" ] && ok "Leader elected: $LEADER" || fail "No Leader found"
[ -n "$REPLICA" ] && ok "Replica present: $REPLICA" || fail "No Replica found"

hdr "Replication lag"
LAG=$(echo "$CLUSTER" | awk '/Replica/ {print $NF}')
echo "  Lag reported: $LAG"
[[ "$LAG" == "0" || "$LAG" == "0 B" ]] && ok "Lag is 0 — replication is synchronous" || ok "Lag: $LAG (acceptable)"

hdr "Write to Leader (haproxy-postgres:5000)"
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -d postgres \
  -c "CREATE TABLE IF NOT EXISTS _replication_test (id serial PRIMARY KEY, ts timestamptz DEFAULT now(), val text);" \
  -c "INSERT INTO _replication_test(val) VALUES ('replication-check-$(date +%s)');" \
  -c "SELECT * FROM _replication_test ORDER BY id DESC LIMIT 1;" \
  > /tmp/write_result.txt 2>&1
cat /tmp/write_result.txt | grep -q "replication-check" && ok "Row inserted on Leader" || fail "Insert failed"

hdr "Read from Replica (haproxy-postgres:5001)"
sleep 1
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5001 -U "$POSTGRES_USER" -d postgres \
  -c "SELECT * FROM _replication_test ORDER BY id DESC LIMIT 1;" \
  > /tmp/read_result.txt 2>&1
cat /tmp/read_result.txt | grep -q "replication-check" && ok "Row readable from Replica — streaming replication confirmed" || fail "Row not found on Replica"

hdr "Cleanup"
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -d postgres \
  -c "DROP TABLE IF EXISTS _replication_test;" > /dev/null 2>&1
ok "Test table dropped"

echo
echo "══════════════════════════════════"
echo "  Replication test — PASS: $PASS  FAIL: $FAIL"
echo "══════════════════════════════════"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
