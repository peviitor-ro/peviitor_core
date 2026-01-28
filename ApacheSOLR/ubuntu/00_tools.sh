#!/bin/bash

# WSL Docker + Solr Setup (always sudo docker)

set -e

echo "=== WSL Docker + Solr Setup (socket + Solr) ==="

echo "[1] Remove old Docker bits (if any)..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "[2] Install prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "[3] Setup Docker apt repo..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -rf /etc/apt/keyrings/docker.asc || true

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[4] Install Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[5] Start Docker daemon in WSL (no systemctl)..."
if ! pgrep -x dockerd >/dev/null; then
  sudo dockerd > /tmp/dockerd.log 2>&1 &
  sleep 5
fi

echo "[6] WSL group + socket permissions..."
sudo groupadd -f docker
sudo usermod -aG docker "$USER" || true
newgrp docker 2>/dev/null || true

if [ -S /var/run/docker.sock ]; then
  sudo chown root:docker /var/run/docker.sock || true
  sudo chmod 660 /var/run/docker.sock || true
fi

echo "[7] Test Docker (with sudo)..."
sudo docker run --rm --entrypoint echo hello-world > /dev/null || {
  echo "Docker test failed. Try: 'wsl --shutdown' in Windows PowerShell, reopen WSL, then rerun this script."
  exit 1
}
echo "Docker access OK with sudo."

echo ""
echo "=== Peviitor Solr Docker Setup ==="

echo "[8] Prepare Solr data dir with correct UID/GID..."
mkdir -p ~/peviitor/solr
sudo docker run --rm -v ~/peviitor/solr:/mnt solr:latest chown -R 8983:8983 /mnt

echo "Solr directory ready: ~/peviitor/solr"

echo "[9] Pull and run solr:latest..."
sudo docker pull solr:latest
sudo docker stop peviitor-solr || true
sudo docker rm peviitor-solr || true

sudo docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest

sleep 10

echo "[10] Container status:"
sudo docker ps | grep peviitor-solr || echo "peviitor-solr not running"

echo ""
echo "=== COMPLETE ==="
echo "✓ Solr UI: http://localhost:8983/solr"
echo "✓ Docker test: sudo docker run hello-world"
echo "If Docker breaks after reboot, run: sudo dockerd > /tmp/dockerd.log 2>&1 &"
