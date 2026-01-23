docker exec -it peviitor-solr bin/solr delete -c job
docker exec -it peviitor-solr solr create_core -c job
