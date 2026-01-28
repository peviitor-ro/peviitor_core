#!/bin/bash
set -e

echo "🚀 Peviitor Solr FINAL START (WSL Ubuntu)"

# Clean old
docker stop peviitor-solr || true
docker rm peviitor-solr || true

# Reset & fix permissions (8983 = Solr UID)
sudo rm -rf ~/peviitor/solr/*
mkdir -p ~/peviitor/solr
sudo chown -R 8983:8983 ~/peviitor/solr
echo "✓ Volum ~/peviitor/solr ready (permissions fixed)"

# Pull latest
docker pull solr:latest
echo "✓ Solr:latest pulled"

# Start cu auto-create core 'job'
docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest solr-precreate job

echo "⏳ Waiting 25s for Solr startup..."
sleep 25

# Status check
docker ps | grep solr
docker logs peviitor-solr | tail -5

echo ""
echo "✅ SOLR READY!"
echo "🌐 UI: http://localhost:8983/solr/#/job"
echo "📁 Folder Windows: \\\\wsl\$\\Ubuntu\\home\\$USER\\peviitor\\solr"
echo ""
echo "Commands rapide:"
echo "  docker stop peviitor-solr"
echo "  docker start peviitor-solr  # Repornește rapid"
echo "  docker logs peviitor-solr"
