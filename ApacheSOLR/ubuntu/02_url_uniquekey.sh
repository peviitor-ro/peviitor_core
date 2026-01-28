#!/usr/bin/env bash
set -e

CONTAINER=peviitor-solr
SCHEMA_PATH=/var/solr/data/job/conf/managed-schema.xml

echo "[1] Setam <uniqueKey>url</uniqueKey> in schema..."

docker exec "$CONTAINER" bash -c "
  set -e

  # Daca avem vechiul uniqueKey=id, il inlocuim cu url
  if grep -q '<uniqueKey>id</uniqueKey>' '$SCHEMA_PATH'; then
    sed -i 's#<uniqueKey>id</uniqueKey>#<uniqueKey>url</uniqueKey>#' '$SCHEMA_PATH'
  fi

  # Ne asiguram ca uniqueKey e in interiorul <schema> si apare o singura data
  # 1) stergem orice <uniqueKey>url</uniqueKey> din primele 20 de linii (in caz ca e aiurea)
  sed -i '1,20{/<uniqueKey>url<\/uniqueKey>/d}' '$SCHEMA_PATH'

  # 2) daca nu exista deloc uniqueKey=url, il inseram dupa <schema ...>
  if ! grep -q '<uniqueKey>url</uniqueKey>' '$SCHEMA_PATH'; then
    sed -i '/<schema name=\"default-config\" version=\"1.7\">/a \  <uniqueKey>url</uniqueKey>' '$SCHEMA_PATH'
  fi

  echo '[OK] uniqueKey= url setat in schema.'

  echo '[2] Verificam/cream field-ul url...'

  # Daca field-ul url nu exista, il inseram dupa field-ul id
  if ! grep -q 'name=\"url\"' '$SCHEMA_PATH'; then
    sed -i '/name=\"id\"/a \  <field name=\"url\" type=\"string\" indexed=\"true\" stored=\"true\" required=\"true\" multiValued=\"false\"\/>' '$SCHEMA_PATH'
    echo '[OK] Field url adaugat in schema.'
  else
    echo '[OK] Field url deja exista in schema.'
  fi
"

echo "[3] Restartam containerul Solr..."
docker restart "$CONTAINER"

echo "[DONE] uniqueKey este acum url pentru core-ul job."
