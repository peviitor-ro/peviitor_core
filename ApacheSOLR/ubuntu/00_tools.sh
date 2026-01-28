#!/bin/bash

# Exit on error
set -e

echo "WSL Docker + Solr Setup (fixes socket permissions)"

# Uninstall old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -rf /etc/apt/keyrings/docker.asc || true

# Add Docker GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start/enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# WSL-specific: Ensure docker group exists and add user
sudo groupadd -f docker    # -f: force if exists
sudo usermod -aG docker "$USER"

# Activate group immediately (best-effort)
newgrp docker 2>/dev/null || true

# CRITICAL WSL FIX: Set docker.sock permissions for group access
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

echo "Docker installed! Testing access..."

# Test Docker (with sudo, as requested)
sudo docker run --rm --entrypoint echo hello-world > /dev/null || {
  echo "Docker failed - restart WSL: 'wsl --shutdown' from Windows PowerShell"
  exit 1
}
echo "Docker access OK!"

echo ""
echo "=== Peviitor Solr Docker Setup ==="

# Create Solr dir with correct UID/GID (8983:8983)
mkdir -p ~/peviitor/solr
sudo docker run --rm -v ~/peviitor/solr:/mnt solr:latest chown -R 8983:8983 /mnt

echo "Solr directory ready: ~/peviitor/solr"

# Pull and run Solr (always via sudo)
sudo docker pull solr:latest
sudo docker stop peviitor-solr || true
sudo docker rm peviitor-solr || true

sudo docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest

sleep 10

echo "Container status:"
sudo docker ps | grep peviitor-solr || echo "peviitor-solr not running"

echo ""
echo "=== COMPLETE ==="
echo "✓ Solr: http://localhost:8983/solr"
echo "✓ Test: sudo docker run hello-world"
echo "WSL Tip: If issues persist, run 'wsl --shutdown' in Windows PowerShell, then reopen WSL."
