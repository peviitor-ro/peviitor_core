#!/usr/bin/env bash
set -e

CONTAINER="peviitor-solr"
SOLR_URL="http://localhost:8983/solr"

echo "=== Setting 'url' as uniqueKey for 'job' core ==="

echo "=== Waiting for Solr to be up ==="
for i in {1..30}; do
  if curl -s "$SOLR_URL/job/admin/ping" >/dev/null 2>&1; then
    echo "Solr job core is UP (attempt $i)."
    break
  fi
  echo "Solr not ready yet (attempt $i), waiting 2s..."
  sleep 2
done

if ! curl -s "$SOLR_URL/job/admin/ping" >/dev/null 2>&1; then
  echo "ERROR: Solr job core not reachable after 60s. Exiting."
  exit 1
fi

sleep 5

echo "=== Ensuring 'url' field exists with indexed=true ==="
curl -s -X POST "$SOLR_URL/job/schema" \
  -H "Content-Type: application/json" \
  -d '{
  "add-field": {
    "name": "url",
    "type": "string",
    "stored": true,
    "indexed": true,
    "required": true,
    "multiValued": false
  }
}' || true

echo "=== Changing uniqueKey from 'id' to 'url' in managed-schema.xml ==="
docker exec "$CONTAINER" bash -c "
  cp /var/solr/data/job/conf/managed-schema.xml /tmp/managed-schema.xml &&
  sed -i 's|<uniqueKey>id</uniqueKey>|<uniqueKey>url</uniqueKey>|g' /tmp/managed-schema.xml &&
  cp /tmp/managed-schema.xml /var/solr/data/job/conf/managed-schema.xml &&
  rm /tmp/managed-schema.xml
"

echo "=== Reloading core ==="
curl -s "$SOLR_URL/admin/cores?action=RELOAD&core=job"

echo ""
echo "=== Verifying uniqueKey ==="
curl -s "$SOLR_URL/job/schema/uniquekey" | python3 -m json.tool || true

echo ""
echo "=== DONE: 'url' is now the uniqueKey for 'job' core ==="
