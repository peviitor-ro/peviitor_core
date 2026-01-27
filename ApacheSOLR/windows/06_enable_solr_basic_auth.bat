@echo off
setlocal ENABLEDELAYEDEXPANSION

echo ==========================================
echo Configurare Basic Auth in Solr 9.10 (Windows + Docker)
echo 1) Genereaza security.json cu userul 'solr'
echo 2) Copiaza in container si restarteaza
echo ==========================================
echo.

REM === 0. Setari de baza ===
set "SECURITY_FILE=C:\peviitor\solr\data\security.json"
set "CONTAINER_NAME=peviitor-solr"
set "SOLR_URL=http://localhost:8983/solr"
REM ATENTIE: parola reala pentru userul solr (ex: SolrRocks)
set "SOLR_ADMIN_USER=solr"
set "SOLR_ADMIN_PASS=SolrRocks"

REM === 1. Creare foldere volum daca nu exista ===
if not exist C:\peviitor\solr (
    mkdir C:\peviitor\solr
)
if not exist C:\peviitor\solr\data (
    mkdir C:\peviitor\solr\data
)

echo.
echo === 2. Generare security.json initial (user solr admin) ===

> "%SECURITY_FILE%" echo {
>> "%SECURITY_FILE%" echo   "authentication": {
>> "%SECURITY_FILE%" echo     "blockUnknown": true,
>> "%SECURITY_FILE%" echo     "class": "solr.BasicAuthPlugin",
>> "%SECURITY_FILE%" echo     "credentials": {
>> "%SECURITY_FILE%" echo       "solr": "IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c="
>> "%SECURITY_FILE%" echo     }
>> "%SECURITY_FILE%" echo   },
>> "%SECURITY_FILE%" echo   "authorization": {
>> "%SECURITY_FILE%" echo     "class": "solr.RuleBasedAuthorizationPlugin",
>> "%SECURITY_FILE%" echo     "user-role": {
>> "%SECURITY_FILE%" echo       "solr": "admin"
>> "%SECURITY_FILE%" echo     },
>> "%SECURITY_FILE%" echo     "permissions": [
>> "%SECURITY_FILE%" echo       { "name": "security-edit", "role": "admin" },
>> "%SECURITY_FILE%" echo       { "name": "read", "role": "admin" },
>> "%SECURITY_FILE%" echo       { "name": "all", "role": "admin" }
>> "%SECURITY_FILE%" echo     ]
>> "%SECURITY_FILE%" echo   }
>> "%SECURITY_FILE%" echo }

echo.
echo === security.json generat: %SECURITY_FILE% ===
type "%SECURITY_FILE%"
echo.
pause

REM === 3. Copiere security.json in container ===
echo.
echo === Copiere security.json in %CONTAINER_NAME%:/var/solr/data/security.json ===
docker cp "%SECURITY_FILE%" %CONTAINER_NAME%:/var/solr/data/security.json

if errorlevel 1 (
    echo.
    echo EROARE la docker cp. Verifica:
    echo  - Docker ruleaza
    echo  - Exista containerul %CONTAINER_NAME%
    echo.
    goto END
)

REM === 4. Restart container Solr ===
echo.
echo === Restart container %CONTAINER_NAME% ===
docker restart %CONTAINER_NAME%

if errorlevel 1 (
    echo.
    echo EROARE la restartul containerului %CONTAINER_NAME%.
    echo.
    goto END
)

echo.
echo === 5. Verificam ca Basic Auth este activa (solr / PAROLA_SOLR) ===
curl.exe -s -u %SOLR_ADMIN_USER%:%SOLR_ADMIN_PASS% "%SOLR_URL%/admin/authentication"
echo.
echo (Daca vezi JSON cu solr.BasicAuthPlugin, e OK.)
echo.
pause

echo ==========================================
echo Gata.
echo  - security.json a fost pus in container
echo  - Userul 'solr' (admin) este configurat
echo  - Te poti loga in UI cu solr / %SOLR_ADMIN_PASS%.
echo ==========================================
echo.

:END
endlocal
pause
