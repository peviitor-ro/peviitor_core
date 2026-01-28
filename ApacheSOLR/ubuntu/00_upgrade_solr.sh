#!/bin/bash

set -e

echo "=== Upgrading peviitor-solr to latest ==="

# Stop and remove existing container
sudo docker stop peviitor-solr || true
sudo docker rm peviitor-solr || true

# Pull latest Solr image
echo "Pulling solr:latest..."
sudo docker pull solr:latest

# Start fresh container with same settings
echo "Starting upgraded Solr container..."
sudo docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest

# Show status
echo ""
echo "Container status:"
sudo docker ps

echo ""
echo "=== UPGRADE COMPLETE ==="
echo "Solr upgraded and running at: http://localhost:8983/solr"
echo "Wait 10-20 seconds for full startup."
