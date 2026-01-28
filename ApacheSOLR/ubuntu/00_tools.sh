#!/bin/bash

set -e

echo "=== SIMPLE Docker + Solr setup (WSL, sudo only) ==="

echo "[1] Install Docker from Ubuntu repo (simple way)..."
sudo apt-get update
sudo apt-get install -y docker.io

echo "[2] Test Docker with sudo..."
sudo docker run --rm hello-world

echo ""
echo "=== Solr container ==="

echo "[3] Create Solr data directory..."
mkdir -p ~/peviitor/solr

echo "[4] Pull and run solr:latest..."
sudo docker pull solr:latest
sudo docker stop peviitor-solr || true
sudo docker rm peviitor-solr || true

sudo docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest

sleep 10

echo "[5] Container status:"
sudo docker ps | grep peviitor-solr || echo "peviitor-solr not running"

echo ""
echo "=== DONE ==="
echo "Solr UI: http://localhost:8983/solr"
echo "Use 'sudo docker ...' for all Docker commands."
