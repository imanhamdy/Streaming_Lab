#!/bin/bash
# ============================================================
#  install-node-exporter.sh
#  A lancer sur VM-DNS (192.168.20.2) et VM-BACKUP (192.168.30.2)
#  Usage : sudo bash install-node-exporter.sh
# ============================================================

set -e

LOKI_SERVER="192.168.10.2"
NODE_NAME="$(hostname)"
NODE_EXPORTER_VERSION="1.8.1"
ARCH="linux-amd64"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && err "Lance ce script en root : sudo bash install-node-exporter.sh"

echo "============================================"
echo "  Installation node_exporter + Promtail"
echo "  Loki cible : $LOKI_SERVER"
echo "  Node       : $NODE_NAME"
echo "============================================"

# ── NODE EXPORTER ─────────────────────────────────────────
log "Téléchargement node_exporter v${NODE_EXPORTER_VERSION}..."
cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

if command -v useradd &>/dev/null; then
  useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
  chown node_exporter:node_exporter /usr/local/bin/node_exporter
  NE_USER="node_exporter"
else
  NE_USER="root"
fi

cat > /etc/systemd/system/node_exporter.service << UNIT
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=${NE_USER}
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
log "node_exporter démarré sur le port 9100"

if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
  ufw allow 9100/tcp comment "node_exporter" 2>/dev/null || true
  log "Port 9100 ouvert (UFW)"
fi

# ── PROMTAIL ──────────────────────────────────────────────
log "Installation Promtail..."

if command -v docker &>/dev/null; then
  mkdir -p /etc/promtail
  cat > /etc/promtail/config.yml << PROMTAIL
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/promtail-positions.yaml

clients:
  - url: http://${LOKI_SERVER}:3100/loki/api/v1/push

scrape_configs:
  - job_name: varlogs
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          host: ${NODE_NAME}
          env: prod
          __path__: /var/log/*.log
PROMTAIL

  docker rm -f promtail 2>/dev/null || true
  docker run -d --name promtail \
    --restart unless-stopped \
    -v /etc/promtail:/etc/promtail \
    -v /var/log:/var/log:ro \
    grafana/promtail:latest \
    -config.file=/etc/promtail/config.yml

  log "Promtail démarré via Docker"
else
  log "Docker absent — Promtail non installé"
fi

echo ""
echo "============================================"
echo "  Terminé !"
echo "  Métriques : http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo "  Logs → Loki : http://${LOKI_SERVER}:3100"
echo "============================================"
