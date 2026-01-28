#!/bin/bash

# Minimal Docker + Solr setup on Ubuntu/WSL (always uses sudo)

set -e

echo "=== STEP 1: Clean containerd conflicts (if any) ==="
sudo apt-get remove -y containerd.io containerd docker docker-engine docker.io docker-ce || true
sudo apt-get -f install -y || true

echo "=== STEP 2: Install Docker (docker.io from Ubuntu repo) ==="
sudo apt-get update
sudo apt-get install -y docker.io

echo "=== STEP 3: Test Docker with sudo ==="
sudo docker run --rm hello-world

echo ""
echo "Docker OK with sudo."

echo ""
echo "=== STEP 4: Setup Solr container ==="

# Create persistent Solr data directory
mkdir -p ~/peviitor/solr

echo "Pulling solr:latest..."
sudo docker pull solr:latest

echo "Stopping/removing old peviitor-solr (if any)..."
sudo docker stop peviitor-solr || true
sudo docker rm peviitor-solr || true

echo "Starting new peviitor-solr container..."
sudo docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest

sleep 10

echo "=== STEP 5: Container status ==="
sudo docker ps | grep peviitor-solr || echo "peviitor-solr not running"

echo ""
echo "=== COMPLETE ==="
echo "Solr UI: http://localhost:8983/solr"
echo "Use 'sudo docker ...' for all Docker commands."
