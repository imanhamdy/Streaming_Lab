#!/usr/bin/env bash
# crowdsec-demo/watch-dashboard.sh
# Run this on the VM during the demo — live terminal dashboard
# Refreshes every 2 seconds

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

INTERVAL=2

render() {
  clear
  NOW=$(date '+%H:%M:%S')
  ALERTS_RAW=$(docker exec crowdsec cscli alerts list -o json 2>/dev/null)
  DECISIONS_RAW=$(docker exec crowdsec cscli decisions list -o json 2>/dev/null)
  ALERT_COUNT=$(echo "$ALERTS_RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo 0)
  DECISION_COUNT=$(echo "$DECISIONS_RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo 0)

  # CAPI bans from metrics
  CAPI_BANS=$(docker exec crowdsec wget -qO- http://localhost:6060/metrics 2>/dev/null \
    | grep 'cs_active_decisions{action="ban",origin="CAPI"' \
    | awk -F' ' '{sum+=$2} END {print int(sum)}')

  echo -e "${BOLD}${CYN}╔══════════════════════════════════════════════════════════════════╗${RST}"
  echo -e "${BOLD}${CYN}║  🛡  CrowdSec Live Dashboard — Streaming Lab          $NOW  ║${RST}"
  echo -e "${BOLD}${CYN}╚══════════════════════════════════════════════════════════════════╝${RST}"
  echo ""

  # Counters row
  if [ "$ALERT_COUNT" -gt 0 ] 2>/dev/null; then
    ALERT_COLOR="$RED"
  else
    ALERT_COLOR="$DIM"
  fi
  if [ "$DECISION_COUNT" -gt 0 ] 2>/dev/null; then
    DEC_COLOR="$RED"
  else
    DEC_COLOR="$DIM"
  fi

  echo -e "  ${BOLD}ALERTES LOCALES${RST}          ${BOLD}DÉCISIONS ACTIVES${RST}         ${BOLD}CAPI BLOCKLIST${RST}"
  echo -e "  ${ALERT_COLOR}${BOLD}    $ALERT_COUNT détectée(s)${RST}          ${DEC_COLOR}${BOLD}    $DECISION_COUNT IP bannie(s)${RST}          ${YLW}${BOLD}  $CAPI_BANS IPs globales${RST}"
  echo ""
  echo -e "${CYN}────────────────────────────────── ALERTES ───────────────────────────────────${RST}"

  docker exec crowdsec cscli alerts list 2>/dev/null

  echo ""
  echo -e "${CYN}─────────────────────────────────── DÉCISIONS ────────────────────────────────${RST}"

  docker exec crowdsec cscli decisions list 2>/dev/null

  echo ""
  echo -e "${CYN}──────────────────────────────── ACQUISITION MÉTRIQUES ───────────────────────${RST}"
  docker exec crowdsec cscli metrics show acquisition 2>/dev/null | grep -v "^+\|^$" | head -6

  echo ""
  echo -e "${DIM}  Rafraîchissement toutes les ${INTERVAL}s · Ctrl+C pour quitter · Console cloud : app.crowdsec.net${RST}"
}

trap 'echo -e "\n${GRN}Dashboard arrêté.${RST}"; exit 0' INT TERM

while true; do
  render
  sleep "$INTERVAL"
done
