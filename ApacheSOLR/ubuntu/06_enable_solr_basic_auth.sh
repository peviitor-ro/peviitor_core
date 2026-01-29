#!/usr/bin/env bash
set -e

echo "=========================================="
echo "Configurare Basic Auth in Solr 9.10 (Ubuntu + Docker)"
echo "Container: peviitor-solr, bind: /home/sebi/peviitor/solr -> /var/solr"
echo "=========================================="
echo

CONTAINER_NAME="peviitor-solr"
SOLR_URL="http://localhost:8983/solr"
SOLR_ADMIN_USER="solr"
SOLR_ADMIN_PASS="SolrRocks"

SOLR_HOST_ROOT="/home/sebi/peviitor/solr"
SECURITY_FILE_HOST="$SOLR_HOST_ROOT/security.json"
SECURITY_FILE_CONTAINER="/var/solr/security.json"

echo "=== 0. Fix permisiuni host pe $SOLR_HOST_ROOT ==="
sudo mkdir -p "$SOLR_HOST_ROOT/data" "$SOLR_HOST_ROOT/logs"
sudo chown -R sebi:sebi "$SOLR_HOST_ROOT"
sudo chmod -R u+rwX "$SOLR_HOST_ROOT"
sudo chown -R 8983:8983 "$SOLR_HOST_ROOT/data" "$SOLR_HOST_ROOT/logs"

echo
echo "=== 1. Generare security.json pe host ==="

cat > "$SECURITY_FILE_HOST" <<'EOF'
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

echo
echo "=== security.json (host): $SECURITY_FILE_HOST ==="
cat "$SECURITY_FILE_HOST"

echo
echo "=== 2. Copiere security.json in container: $SECURITY_FILE_CONTAINER ==="
docker cp "$SECURITY_FILE_HOST" "$CONTAINER_NAME:$SECURITY_FILE_CONTAINER"

echo
echo "=== 3. Pornim containerul pentru a seta owner pe security.json ==="
docker start "$CONTAINER_NAME"

echo
echo "=== 4. Setam owner solr:solr pe $SECURITY_FILE_CONTAINER in container ==="
docker exec -u root "$CONTAINER_NAME" chown solr:solr "$SECURITY_FILE_CONTAINER"

echo
echo "=== 5. Restart container $CONTAINER_NAME ==="
docker restart "$CONTAINER_NAME"

echo
echo "=== 6. Verificam Basic Auth (solr / PAROLA_SOLR) ==="
curl -s -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASS" "$SOLR_URL/admin/authentication"
echo
echo "(Daca vezi JSON cu solr.BasicAuthPlugin, e OK.)"
echo
echo "=========================================="
echo "Gata: Basic Auth activata (solr / $SOLR_ADMIN_PASS)."
echo "=========================================="
