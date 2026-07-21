#!/bin/bash
set -e

echo "🚀 Peviitor Solr START (Raspberry Pi)"

# Clean old
docker stop peviitor-solr || true
docker rm peviitor-solr || true

# Reset & fix permissions (8983 = Solr UID)
sudo rm -rf ~/peviitor/solr/*
mkdir -p ~/peviitor/solr
sudo chown -R 8983:8983 ~/peviitor/solr
echo "✓ Volume ~/peviitor/solr ready (permissions fixed)"

# Pull latest multi-arch image
docker pull solr:latest
echo "✓ solr:latest pulled"

# Start with auto-create core 'job' on port 8983
docker run -d \
  --name peviitor-solr \
  --restart unless-stopped \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  -e SOLR_HEAP=2g \
  solr:latest solr-precreate job

echo "⏳ Waiting 25s for Solr startup..."
sleep 25

# Status check
docker ps | grep peviitor-solr || true
docker logs peviitor-solr | tail -20 || true

echo ""
echo "✅ SOLR READY!"
echo "🌐 UI: http://<raspberry-pi-ip>:8983/solr/#/job"
echo ""
echo "Useful commands:"
echo " docker stop peviitor-solr"
echo " docker start peviitor-solr"
echo " docker logs peviitor-solr"
