#!/usr/bin/env bash
# Re-installare SOLR Test Environment pe Raspberry Pi 4
# Utilizare: bash install_solr_test.sh
set -e

# Credentials — overridable via environment variables
: "${SOLR_USER:=solr}"
: "${SOLR_PASS:=change_me}"

echo "=== 1. Install Docker (daca nu exista) ==="
if ! command -v docker &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
  echo "Docker instalat. Logout/login sau 'newgrp docker'."
  exit 0
fi
echo "Docker already installed: $(docker --version)"

echo "=== 2. Pull Solr image ==="
docker pull solr:latest

echo "=== 3. Clean old container ==="
docker stop peviitor-solr 2>/dev/null || true
docker rm peviitor-solr 2>/dev/null || true

echo "=== 4. Prepare directories ==="
mkdir -p ~/peviitor/solr
sudo chown -R 8983:8983 ~/peviitor/solr

echo "=== 5. Start Solr container with job core ==="
docker run -d \
  --name peviitor-solr \
  -p 8983:8983 \
  -v ~/peviitor/solr:/var/solr \
  solr:latest solr-precreate job

echo "=== 6. Wait for Solr startup (45s) ==="
sleep 45

echo "=== 7. Set url as uniqueKey ==="
docker cp peviitor-solr:/var/solr/data/job/conf/managed-schema.xml /tmp/managed-schema.xml
sed -i 's|<uniqueKey>id</uniqueKey>|<uniqueKey>url</uniqueKey>|' /tmp/managed-schema.xml
sed -i 's|<field name="id" type="string" multiValued="false" indexed="true" required="true" stored="true"/>|<field name="id" type="string" multiValued="false" indexed="true" stored="true"/>|' /tmp/managed-schema.xml
sed -i 's|<field name="url" type="string" indexed="true" stored="true"/>|<field name="url" type="string" multiValued="false" indexed="true" required="true" stored="true"/>|' /tmp/managed-schema.xml
docker cp /tmp/managed-schema.xml peviitor-solr:/var/solr/data/job/conf/managed-schema.xml
docker exec -u root peviitor-solr chown solr:solr /var/solr/data/job/conf/managed-schema.xml
docker restart peviitor-solr
sleep 30

echo "=== 8. Add job schema fields ==="
SOLR_URL="http://localhost:8983/solr/job"

curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "title", "type": "text_general", "stored": true, "indexed": true, "multiValued": false}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "company", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "cif", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "location", "type": "text_general", "stored": true, "indexed": true, "multiValued": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "workmode", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "status", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "salary", "type": "text_general", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "date", "type": "pdate", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "vdate", "type": "pdate", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "expirationdate", "type": "pdate", "stored": true, "indexed": true}}'
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"add-field": {"name": "tags", "type": "text_general", "stored": true, "indexed": true, "multiValued": true}}'

echo "=== 9. Add copyFields for job ==="
for FIELD in url title company location tags workmode salary; do
  curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
    -d "{\"add-copy-field\": {\"source\": \"${FIELD}\", \"dest\": \"_text_\"}}"
done

echo "=== 10. Delete old id field ==="
curl -s -X POST "$SOLR_URL/schema" -H "Content-Type: application/json" \
  -d '{"delete-field": {"name": "id"}}'

echo "=== 11. Add SuggestComponent ==="
curl -s -X POST "$SOLR_URL/config" -H "Content-Type: application/json" -d '{
  "add-searchcomponent": {
    "name": "suggest",
    "class": "solr.SuggestComponent",
    "suggester": {
      "name": "jobTitleSuggester",
      "lookupImpl": "FuzzyLookupFactory",
      "dictionaryImpl": "DocumentDictionaryFactory",
      "field": "title",
      "suggestAnalyzerFieldType": "text_general",
      "buildOnCommit": "true",
      "buildOnStartup": "false"
    }
  }
}'

curl -s -X POST "$SOLR_URL/config" -H "Content-Type: application/json" -d '{
  "add-requesthandler": {
    "name": "/suggest",
    "class": "solr.SearchHandler",
    "startup": "lazy",
    "defaults": {
      "suggest": "true",
      "suggest.dictionary": "jobTitleSuggester",
      "suggest.count": "10"
    },
    "components": ["suggest"]
  }
}'

echo "=== 12. Create company core ==="
docker exec peviitor-solr cp -r /opt/solr-10.0.0/server/solr/configsets/_default/conf /var/solr/data/company/
docker exec -u root peviitor-solr chown -R solr:solr /var/solr/data/company
curl -s "http://localhost:8983/solr/admin/cores?action=CREATE&name=company&instanceDir=company"

echo "=== 13. Add company schema fields ==="
CSOLR="http://localhost:8983/solr/company"
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "company", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "status", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "location", "type": "text_general", "stored": true, "indexed": true, "multiValued": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "website", "type": "string", "stored": true, "indexed": true, "multiValued": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "career", "type": "string", "stored": true, "indexed": true, "multiValued": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "brand", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "group", "type": "string", "stored": true, "indexed": true}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "lastScraped", "type": "string", "stored": true, "indexed": false}}'
curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" -d '{"add-field": {"name": "scraperFile", "type": "string", "stored": true, "indexed": false}}'

echo "=== 14. Add copyFields for company ==="
for FIELD in company location website brand group; do
  curl -s -X POST "$CSOLR/schema" -H "Content-Type: application/json" \
    -d "{\"add-copy-field\": {\"source\": \"${FIELD}\", \"dest\": \"_text_\"}}"
done

echo "=== 15. Enable Basic Auth ==="
cat > /tmp/security.json << 'EOF'
{
  "authentication": {
    "blockUnknown": true,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "solr": "IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c="
    }
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "user-role": {
      "solr": "admin"
    },
    "permissions": [
      { "name": "security-edit", "role": "admin" },
      { "name": "read", "role": "admin" },
      { "name": "all", "role": "admin" }
    ]
  }
}
EOF
docker cp /tmp/security.json peviitor-solr:/var/solr/data/security.json
docker exec -u root peviitor-solr chown solr:solr /var/solr/data/security.json
docker restart peviitor-solr

echo ""
echo "=== INSTALARE COMPLETA ==="
echo "SOLR: http://localhost:8983/solr"
echo "User: solr / Parola: vezi api.env"
echo "Cores: job (uniqueKey=url), company (uniqueKey=id)"
echo "Documente: $(curl -s -u $SOLR_USER:$SOLR_PASS 'http://localhost:8983/solr/job/select?q=*:*&wt=json' | python3 -c "import json,sys; print(json.load(sys.stdin)['response']['numFound'])") in job, $(curl -s -u $SOLR_USER:$SOLR_PASS 'http://localhost:8983/solr/company/select?q=*:*&wt=json' | python3 -c "import json,sys; print(json.load(sys.stdin)['response']['numFound'])") in company"
