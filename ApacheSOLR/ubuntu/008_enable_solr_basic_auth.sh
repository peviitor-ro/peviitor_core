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

echo "=== 0. Pregatim directorul host (creare + permisiuni) ==="
sudo mkdir -p "$SOLR_HOST_ROOT"
sudo chown -R sebi:sebi "$SOLR_HOST_ROOT"
sudo chmod -R u+rwX "$SOLR_HOST_ROOT"
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
ls -l "$SECURITY_FILE_HOST"
echo

echo "=== 2. Asiguram permisiunile pentru volumele data/logs (UID 8983) ==="
sudo mkdir -p "$SOLR_HOST_ROOT/data" "$SOLR_HOST_ROOT/logs"
sudo chown -R 8983:8983 "$SOLR_HOST_ROOT/data" "$SOLR_HOST_ROOT/logs"
sudo chmod -R u+rwX "$SOLR_HOST_ROOT/data" "$SOLR_HOST_ROOT/logs"
echo

echo "=== 3. Copiere security.json in container (via /tmp) ==="
docker cp "$SECURITY_FILE_HOST" "$CONTAINER_NAME:/tmp/security.json"
echo

echo "=== 4. Mutam in SOLR_HOME (=/var/solr/data) si setam owner ==="
docker exec -u root "$CONTAINER_NAME" bash -lc '
  SOLR_HOME=${SOLR_HOME:-/var/solr/data}
  mkdir -p "$SOLR_HOME"
  cp /tmp/security.json "$SOLR_HOME/security.json"
  chown solr:solr "$SOLR_HOME/security.json"
  rm -f /tmp/security.json
'
echo

echo "=== 5. Restart container $CONTAINER_NAME ==="
docker restart "$CONTAINER_NAME"
echo

echo "=== 6. Verificam Basic Auth (solr / PAROLA_SOLR) ==="
echo "Fara credentiale (ar trebui 401):"
curl -i "$SOLR_URL/admin/authentication" | head -n 5 || true
echo
echo "Cu credentiale (ar trebui JSON cu BasicAuthPlugin):"
curl -s -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASS" "$SOLR_URL/admin/authentication" || true
echo
echo
echo "=========================================="
echo "Gata: Basic Auth activata (solr / $SOLR_ADMIN_PASS)."
echo "=========================================="