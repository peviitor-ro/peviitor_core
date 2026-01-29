#!/usr/bin/env bash
set -e

SOLR_URL="http://localhost:8983/solr/company"

echo "=== Add fields ==="

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

# website (multiValued)
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "website",
      "type": "string",
      "stored": true,
      "indexed": true,
      "multiValued": true
    }
  }'

# career (multiValued)
curl -s -X POST "$SOLR_URL/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "career",
      "type": "string",
      "stored": true,
      "indexed": true,
      "multiValued": true
    }
  }'

echo
echo "=== Add copyFields into _text_ ==="

for FIELD in company location website; do
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
echo "=== DONE ==="
