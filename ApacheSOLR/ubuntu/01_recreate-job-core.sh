sudo docker exec peviitor-solr bin/solr delete -c job
sudo docker exec -it peviitor-solr bin/solr create_core -c job

#!/bin/bash
# make-job-managed-only.sh
# Usage: chmod +x make-job-managed-only.sh && ./make-job-managed-only.sh

set -e

CORE=job
CONTAINER=peviitor-solr
CONF_DIR="/var/solr/data/$CORE/conf"
SOLR_ADMIN="http://localhost:8983/solr/admin/cores"

echo "=== Make '$CORE' use managed-schema (no field changes) ==="

echo "[1] Switch schemaFactory to ManagedIndexSchemaFactory..."
sudo docker exec "$CONTAINER" \
  sed -i 's#<schemaFactory.*#<schemaFactory class="ManagedIndexSchemaFactory"><bool name="mutable">true</bool><str name="managedSchemaResourceName">managed-schema</str></schemaFactory>#' \
  "$CONF_DIR/solrconfig.xml"

echo "[2] Ensure managed-schema exists (copy from schema.xml if present)..."
sudo docker exec "$CONTAINER" sh -c '
  if [ -f '"$CONF_DIR"'/schema.xml ] && [ ! -f '"$CONF_DIR"'/managed-schema ]; then
    cp '"$CONF_DIR"'/schema.xml '"$CONF_DIR"'/managed-schema
    chown solr:solr '"$CONF_DIR"'/managed-schema
  fi
'

echo "[3] Reload core..."
curl "$SOLR_ADMIN?action=RELOAD&core=$CORE"
echo ""
echo "=== DONE ==="
echo "Now the '$CORE' schema is managed + editable."
echo "Use UI (Schema tab) or /$CORE/schema API to add fields manually."
