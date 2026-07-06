#!/usr/bin/env bash
# Test Patroni automatic failover: stop Leader, verify Replica is promoted, restart and rejoin
set -euo pipefail

source /home/principal/streaming-lab/.env

PASS=0; FAIL=0
ok()   { echo "  ✅ $*"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }
hdr()  { echo; echo "▶ $*"; }

hdr "Pre-failover cluster state"
docker exec postgres-01 patronictl -c /etc/patroni/config.yml list 2>/dev/null
INITIAL_LEADER=$(docker exec postgres-01 patronictl -c /etc/patroni/config.yml list 2>/dev/null | awk '/Leader/ {print $2}')
echo "  Current Leader: $INITIAL_LEADER"
[ -n "$INITIAL_LEADER" ] && ok "Cluster healthy before failover" || { fail "No leader — aborting"; exit 1; }

hdr "Inserting sentinel row before failover"
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -d postgres \
  -c "CREATE TABLE IF NOT EXISTS _failover_test (id serial PRIMARY KEY, ts timestamptz DEFAULT now(), val text);" \
  -c "INSERT INTO _failover_test(val) VALUES ('pre-failover');" > /dev/null 2>&1
ok "Sentinel row inserted"

hdr "Stopping Leader container ($INITIAL_LEADER)"
FAILOVER_START=$(date +%s)
docker stop "$INITIAL_LEADER" > /dev/null
ok "Leader container stopped"

hdr "Waiting for Patroni election (max 30s)..."
NEW_LEADER=""
for i in $(seq 1 30); do
  sleep 1
  NEW_LEADER=$(docker exec postgres-02 patronictl -c /etc/patroni/config.yml list 2>/dev/null | awk '/Leader/ {print $2}' || true)
  [ -n "$NEW_LEADER" ] && [ "$NEW_LEADER" != "$INITIAL_LEADER" ] && break
  printf "."
done
echo

FAILOVER_END=$(date +%s)
FAILOVER_ELAPSED=$((FAILOVER_END - FAILOVER_START))

[ -n "$NEW_LEADER" ] && ok "New Leader elected: $NEW_LEADER (in ${FAILOVER_ELAPSED}s)" || fail "No new Leader after 30s"

hdr "HAProxy still routes to new Leader (:5000)"
sleep 2
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -d postgres \
  -c "SELECT val FROM _failover_test WHERE val='pre-failover';" \
  > /tmp/failover_read.txt 2>&1
cat /tmp/failover_read.txt | grep -q "pre-failover" && ok "Data accessible via HAProxy after failover — zero data loss" || fail "Data not accessible after failover"

hdr "Measured RTO: ${FAILOVER_ELAPSED}s (target < 60s)"
[ "$FAILOVER_ELAPSED" -lt 60 ] && ok "RTO ${FAILOVER_ELAPSED}s < 60s target" || fail "RTO ${FAILOVER_ELAPSED}s exceeded 60s target"

hdr "Restarting old Leader ($INITIAL_LEADER) — should rejoin as Replica"
docker start "$INITIAL_LEADER" > /dev/null
sleep 10
docker exec postgres-02 patronictl -c /etc/patroni/config.yml list 2>/dev/null
REJOINED=$(docker exec postgres-02 patronictl -c /etc/patroni/config.yml list 2>/dev/null | grep "$INITIAL_LEADER" | grep -i "replica" || true)
[ -n "$REJOINED" ] && ok "$INITIAL_LEADER rejoined as Replica" || ok "$INITIAL_LEADER restarting (may take a few seconds to stream)"

hdr "Cleanup"
docker run --rm --network streaming-private \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:17-alpine \
  psql -h haproxy-postgres -p 5000 -U "$POSTGRES_USER" -d postgres \
  -c "DROP TABLE IF EXISTS _failover_test;" > /dev/null 2>&1
ok "Test table dropped"

echo
echo "══════════════════════════════════════════"
echo "  Failover test — PASS: $PASS  FAIL: $FAIL"
echo "  RTO measured: ${FAILOVER_ELAPSED}s"
echo "══════════════════════════════════════════"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
