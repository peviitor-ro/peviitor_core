#!/bin/bash
set -e  # Oprește la eroare


echo "================ CLEAN SOLR DOCKER ENV ================"

# 1. Stergem containerele legate de Solr
echo "=== 1. Stergem containerele cu nume care contin 'solr' ==="
SOLR_CONTAINERS=$(docker ps -a --filter "name=solr" --format '{{.ID}}')

if [ -z "$SOLR_CONTAINERS" ]; then
  echo "Nu exista containere cu 'solr' in nume."
else
  echo "Containere gasite:"
  docker ps -a --filter "name=solr"
  echo "Oprire + stergere..."
  docker stop $SOLR_CONTAINERS || true
  docker rm $SOLR_CONTAINERS || true
fi
echo

# 2. Stergem imaginile Docker cu nume care contin 'solr'
echo "=== 2. Stergem imaginile cu nume care contin 'solr' ==="
SOLR_IMAGES=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep -i solr | awk '{print $2}')

if [ -z "$SOLR_IMAGES" ]; then
  echo "Nu exista imagini cu 'solr' in nume."
else
  echo "Imagini gasite:"
  docker images | grep -i solr || true
  echo "Stergere imagini..."
  docker rmi -f $SOLR_IMAGES || true
fi
echo

# 3. Stergem volume orfane legate de solr (optional, destul de safe)
echo "=== 3. Stergem volume Docker cu nume care contin 'solr' (daca exista) ==="
SOLR_VOLUMES=$(docker volume ls --format '{{.Name}}' | grep -i solr || true)

if [ -z "$SOLR_VOLUMES" ]; then
  echo "Nu exista volume cu 'solr' in nume."
else
  echo "Volume gasite:"
  echo "$SOLR_VOLUMES"
  echo "Stergere volume..."
  docker volume rm $SOLR_VOLUMES || true
fi
echo

# 4. Stergem directorul ~/peviitor de pe host
TARGET_DIR="$HOME/peviitor"
echo "=== 4. Stergem directorul $TARGET_DIR ==="
if [ -d "$TARGET_DIR" ]; then
  read -p "Esti sigur ca vrei sa stergi TOT din $TARGET_DIR ? (include fisiere root) [yes/NO] " CONFIRM
  if [ "$CONFIRM" = "yes" ]; then
    sudo rm -rf "$TARGET_DIR"
    echo "Sters (cu sudo): $TARGET_DIR"
  else
    echo "Abandonam stergerea $TARGET_DIR."
  fi
else
  echo "Directorul $TARGET_DIR nu exista, nimic de sters."
fi


echo
echo "================ CLEAN DONE ================"


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