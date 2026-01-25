docker exec -it peviitor-solr bin/solr delete -c company
docker exec -it peviitor-solr solr create_core -c company
