#!/bin/bash
set -e  # Oprește la eroare

echo "=== Verifică și instalează Docker idempotent ==="

# Stop docker dacă rulează
sudo systemctl stop docker || true
sudo systemctl stop containerd || true

# Curăță repo/chei vechi (safe)
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc

# Instalează dependențe
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Creează dir keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Descarcă GPG
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Adaugă repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update și instalează (apt e safe dacă există)
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start/enable service (safe)
sudo systemctl enable --now docker
sudo systemctl enable --now containerd

# Grup user (safe, nu dă eroare dacă există)
sudo groupadd -f docker
sudo usermod -aG docker $USER

echo "=== Docker instalat! Rulează 'newgrp docker' sau logout/login ==="
docker --version || echo "Eroare versiune"