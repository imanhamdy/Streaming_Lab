#!/usr/bin/env bash
# crowdsec-demo/attack.sh
# ⚠ RUN THIS FROM YOUR LAPTOP, NOT THE SERVER
# The attack must come from an external IP to bypass CrowdSec's private-IP whitelist
#
# Usage:
#   ./attack.sh                  # SSH to 86.194.44.107, HTTP to jellyfin.duoowatch.com
#   ./attack.sh 1.2.3.4          # custom server IP

SERVER_IP="${1:-86.194.44.107}"
HTTP_TARGET="https://jellyfin.duoowatch.com"

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; BOLD='\033[1m'; RST='\033[0m'

MY_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 api.ipify.org 2>/dev/null || echo 'unknown')

echo -e "${BOLD}${CYN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          🛡  CrowdSec Attack Demo — Streaming Lab        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RST}"
echo -e "  Votre IP   : ${BOLD}$MY_IP${RST}"
echo -e "  Serveur    : ${BOLD}$SERVER_IP${RST}"
echo ""

# Guard: refuse if running on the server itself
if [ "$MY_IP" = "$SERVER_IP" ]; then
  echo -e "${RED}${BOLD}  ✗ ERREUR : Vous êtes sur le serveur lui-même !${RST}"
  echo ""
  echo "  Ce script doit être lancé depuis votre LAPTOP, pas depuis la VM."
  echo "  Copiez-le sur votre machine locale et relancez :"
  echo ""
  echo -e "  ${CYN}scp principal@$SERVER_IP:~/streaming-lab/infra/crowdsec-demo/attack.sh ./${RST}"
  echo -e "  ${CYN}./attack.sh${RST}"
  echo ""
  exit 1
fi

echo -e "  ${GRN}✓ IP externe confirmée — l'attaque sera détectée par CrowdSec${RST}"
echo ""

# ── SSH Brute Force ───────────────────────────────────────────────────────────
echo -e "${RED}[1/2] SSH brute-force${RST}"
echo "      Scénario : crowdsecurity/sshd-bruteforce"
echo "      Seuil    : 10 tentatives → alerte + ban 4h"
echo ""

USERS=("root" "admin" "ubuntu" "user" "pi" "test" "deploy" "postgres" "redis" "support" "operator" "backup")
for i in "${!USERS[@]}"; do
  user="${USERS[$i]}"
  printf "\r  ${RED}→${RST} [%2d/%d] ssh %s@%s " "$((i+1))" "${#USERS[@]}" "$user" "$SERVER_IP"
  # sshpass with wrong password → generates Failed password in auth.log
  sshpass -p "wrongpassword123" ssh \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=4 \
    -o PasswordAuthentication=yes \
    -o PubkeyAuthentication=no \
    "${user}@${SERVER_IP}" exit 2>/dev/null &
done
wait
echo -e "\n  ${GRN}✓ ${#USERS[@]} tentatives SSH avec mauvais mot de passe${RST}"
sleep 2

# ── HTTP Scan ─────────────────────────────────────────────────────────────────
# Note: HTTP attacks go through Cloudflare tunnel (IP = 192.168.10.2 in Traefik logs)
# → whitelisted by CrowdSec. SSH is the reliable path for this demo.
echo ""
echo -e "${YLW}[2/2] HTTP scan (optionnel — via Cloudflare, IP masquée)${RST}"
read -rp "  Lancer quand même pour voir les métriques Traefik ? [o/N] " yn
if [[ "$yn" == "o" || "$yn" == "O" ]]; then
  PATHS=("/.env" "/.git/config" "/wp-admin/" "/phpmyadmin/" "/admin/" "/.aws/credentials"
         "/backup.zip" "/database.sql" "/actuator/env" "/actuator/heapdump" "/console/"
         "/xmlrpc.php" "/../../../etc/passwd" "/server-status" "/elmah.axd")
  for i in "${!PATHS[@]}"; do
    printf "\r  → [%2d/%d] %s" "$((i+1))" "${#PATHS[@]}" "${PATHS[$i]}"
    curl -s -o /dev/null -m 4 -A "Nuclei/2.9" "$HTTP_TARGET${PATHS[$i]}" &
  done
  wait
  echo -e "\n  ${GRN}✓ ${#PATHS[@]} requêtes HTTP envoyées (visible dans les métriques Traefik)${RST}"
fi

echo ""
echo -e "${BOLD}${GRN}✅ Attaque terminée — résultats dans ~30s${RST}"
echo ""
echo -e "  Sur la VM, surveiller :"
echo -e "    ${CYN}./infra/crowdsec-demo/watch-dashboard.sh${RST}"
echo ""
echo -e "  Console cloud :"
echo -e "    ${BOLD}https://app.crowdsec.net → Alerts → Decisions${RST}"
