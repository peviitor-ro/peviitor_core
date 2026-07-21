#!/bin/bash
set -e

echo "=== Upgrading peviitor-solr to latest (Raspberry Pi) ==="

# Stop and remove existing container
docker stop peviitor-solr || true
docker rm peviitor-solr || true

# Pull latest Solr image (multi-arch, works on ARM)
echo "Pulling solr:latest..."
docker pull solr:latest

# Start fresh container with same settings (volume and port must match 001 script)
echo "Starting upgraded Solr container..."
docker run -d \
  --name peviitor-solr \
  --restart unless-stopped \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  -e SOLR_HEAP=2g \
  solr:latest

echo ""
echo "Container status:"
docker ps | grep peviitor-solr || true
echo ""
echo "=== UPGRADE COMPLETE ==="
echo "Solr upgraded and running at: http://localhost:8983/solr"
echo "Wait 10–20 seconds for full startup."
