sudo docker exec peviitor-solr bin/solr delete -c job
sudo docker exec -it peviitor-solr bin/solr create_core -c job