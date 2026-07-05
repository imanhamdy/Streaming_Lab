#!/bin/bash
set -e

echo "==> Installing Docker Engine..."

sudo apt update && sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker "$USER"

echo "==> Docker installed: $(docker --version)"

echo "==> Creating Docker networks..."

create_network() {
  local name="$1"
  local flags="${2:-}"
  if docker network ls --format '{{.Name}}' | grep -q "^${name}$"; then
    echo "    [skip] ${name} already exists"
  else
    docker network create $flags "${name}"
    echo "    [ok]   ${name} created"
  fi
}

# Public: Traefik + all URL-exposed services
create_network streaming-public

# Private: databases, storage, internal app traffic (no external routing)
create_network streaming-private "--internal"

# Monitoring: Prometheus, Loki, exporters, cAdvisor, Grafana
create_network streaming-monitoring

echo ""
echo "==> Done. Run 'newgrp docker' or re-login to use Docker without sudo."
docker network ls
