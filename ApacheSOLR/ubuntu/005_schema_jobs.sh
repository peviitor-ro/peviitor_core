#!/usr/bin/env bash
set -e
SOLR_URL="http://localhost:8983/solr/job"

echo "=== Verificam daca peviitor-solr este UP pentru core job ==="
for i in {1..30}; do
  if curl -s "$SOLR_URL/admin/ping" >/dev/null 2>&1; then
    echo "Solr job core este UP (incercare $i)."
    break
  fi
  echo "Solr nu raspunde inca (incercare $i), mai asteptam 1s..."
  sleep 1
done

if ! curl -s "$SOLR_URL/admin/ping" >/dev/null 2>&1; then
  echo "EROARE: Solr job core NU raspunde dupa 30s. Iesim."
  exit 1
fi

echo "Asteptam inca 25s pentru a termina loading-ul core-ului job..."
sleep 25

echo "=== Add fields (except url) ==="

# title
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "title",
      "type": "text_general",
      "stored": true,
      "indexed": true,
      "multiValued": false
    }
  }'

# company
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "company",
      "type": "string",
      "stored": true,
      "indexed": true
    }
  }'

# cif
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "cif",
      "type": "string",
      "stored": true,
      "indexed": true
    }
  }'

# location
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "location",
      "type": "text_general",
      "stored": true,
      "indexed": true
    }
  }'

# workmode
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "workmode",
      "type": "string",
      "stored": true,
      "indexed": true
    }
  }'

# status
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "status",
      "type": "string",
      "stored": true,
      "indexed": true
    }
  }'

# salary
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": '\"salary\"',
      "type": "text_general",
      "stored": true,
      "indexed": true
    }
  }'

# date
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "date",
      "type": "pdate",
      "stored": true,
      "indexed": true
    }
  }'

# vdate
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "vdate",
      "type": "pdate",
      "stored": true,
      "indexed": true
    }
  }'

# expirationdate
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "expirationdate",
      "type": "pdate",
      "stored": true,
      "indexed": true
    }
  }'

# tags (multiValued)
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "tags",
      "type": "text_general",
      "stored": true,
      "indexed": true,
      "multiValued": true
    }
  }'

echo
echo "=== Add copyFields into _text_ ==="

for FIELD in url title company location tags workmode salary; do
  curl -s -X POST "$SOLR_URL/schema" \
    -H "Content-Type: application/json" \
    -d "{
      \"add-copy-field\": {
        \"source\": \"${FIELD}\",
        \"dest\": \"_text_\"
      }
    }"
done

echo
echo "=== Delete old id field ==="

curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  --data-binary '{
    "delete-field": {
      "name": "id"
    }
  }'

echo
echo "=== DONE ==="
