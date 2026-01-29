#!/bin/bash
set -e

echo "🔄 Recreate Solr 'company' core..."

# Check if container runs
if ! docker ps | grep -q peviitor-solr; then
  echo "❌ peviitor-solr not running! Start first: ./start-solr.sh"
  exit 1
fi

sleep 2

# Delete existing core (ignores if not exists)
docker exec peviitor-solr /opt/solr/bin/solr delete -c company || true
sleep 2

# Create fresh core
docker exec peviitor-solr /opt/solr/bin/solr create_core -c company

echo ""
echo "✅ COMPANY CORE RECREATED!"
echo "🌐 Access: http://localhost:8983/solr/#/company"
echo ""
echo "Next: Run your schema setup script"
