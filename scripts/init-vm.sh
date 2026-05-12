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

for network in streaming-net db-net monitoring-net storage-net; do
  if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
    echo "    [skip] ${network} already exists"
  else
    docker network create "${network}"
    echo "    [ok]   ${network} created"
  fi
done

echo ""
echo "==> Done. Run 'newgrp docker' or re-login to use Docker without sudo."
docker network ls
