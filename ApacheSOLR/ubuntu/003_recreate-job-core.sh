#!/bin/bash
set -e

echo "🔄 Recreate Solr 'job' core..."

# Check if container runs
if ! docker ps | grep -q peviitor-solr; then
    echo "❌ peviitor-solr not running! Start first: ./start-solr.sh"
    exit 1
fi

sleep 2

# Delete existing core (ignores if not exists)
docker exec peviitor-solr /opt/solr/bin/solr delete -c job || true
sleep 2

# Create fresh core
docker exec peviitor-solr /opt/solr/bin/solr create_core -c job

echo ""
echo "✅ JOB CORE RECREATED!"
echo "🌐 Access: http://localhost:8983/solr/#/job"
echo ""
echo "Next: Run your schema setup script"
