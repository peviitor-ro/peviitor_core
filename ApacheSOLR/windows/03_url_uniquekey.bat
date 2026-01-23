@echo off
setlocal

set SCHEMA_PATH=C:\peviitor\solr\data\job\conf\managed-schema.xml

powershell -Command "(Get-Content -Path '%SCHEMA_PATH%' -Raw) -replace '<uniqueKey>id</uniqueKey>','<uniqueKey>url</uniqueKey>' | Set-Content -Path '%SCHEMA_PATH%'"

echo UniqueKey schimbat din id in url in %SCHEMA_PATH%
echo Acum trebuie sa restartezi containerul Solr:
docker restart peviitor-solr

endlocal
