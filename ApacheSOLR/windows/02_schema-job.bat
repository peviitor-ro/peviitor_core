@echo off
setlocal

REM URL de baza pentru core-ul job
set SOLR_URL=http://localhost:8983/solr/job

echo === Add fields ===

REM url - primary key dorit (similar cu id standard)
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"url\",\"type\":\"string\",\"stored\":true,\"indexed\":true,\"required\":true,\"multiValued\":false,\"docValues\":true}}"

REM title
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"title\",\"type\":\"text_general\",\"stored\":true,\"indexed\":true,\"multiValued\":false}}"

REM company
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"company\",\"type\":\"text_general\",\"stored\":true,\"indexed\":true}}"

REM cif
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"cif\",\"type\":\"string\",\"stored\":true,\"indexed\":true}}"

REM location
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"location\",\"type\":\"text_general\",\"stored\":true,\"indexed\":true}}"

REM workmode
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"workmode\",\"type\":\"string\",\"stored\":true,\"indexed\":true}}"

REM status
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"status\",\"type\":\"string\",\"stored\":true,\"indexed\":true}}"

REM salary
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"salary\",\"type\":\"text_general\",\"stored\":true,\"indexed\":true}}"

REM date (folosim pdate, tip existent in _default configset)
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"date\",\"type\":\"pdate\",\"stored\":true,\"indexed\":true}}"

REM vdate
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"vdate\",\"type\":\"pdate\",\"stored\":true,\"indexed\":true}}"

REM expirationdate
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"expirationdate\",\"type\":\"pdate\",\"stored\":true,\"indexed\":true}}"

REM tags (multiValued)
curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-field\":{\"name\":\"tags\",\"type\":\"text_general\",\"stored\":true,\"indexed\":true,\"multiValued\":true}}"

echo.
echo === Add copyFields into _text_ ===

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"url\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"title\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"company\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"location\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"tags\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"workmode\",\"dest\":\"_text_\"}}"

curl -s -X POST "%SOLR_URL%/schema" ^
  -H "Content-Type: application/json" ^
  -d "{\"add-copy-field\":{\"source\":\"salary\",\"dest\":\"_text_\"}}"

echo.
echo === DONE ===
endlocal
