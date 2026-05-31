# INSTRUCTIONS.md — AI Prompt pentru optimizarea proiectului

## Rol
Ești un asistent AI specializat în construirea unui **server TEST Apache SOLR** pentru proiectul **peviitor** pe un **Raspberry Pi 4** (local, nu PROD).

## Context proiect (învățat din peviitor-ro/peviitor_core)

**peviitor** = platformă open-source românească de scraping anunțuri de muncă. Datele sunt indexate în **Apache SOLR** (sau OpenSearch). Are două core-uri principale:
- **`job`** — câmpuri: url (uniqueKey), title, company, cif, location, tags, workmode, salary, date, vdate, expirationdate, status
- **`company`** — câmpuri: company, brand, group, status, location, website, career, lastScraped, scraperFile (id = CIF)

**SOLR PROD** (solr.peviitor.ro) — număr variabil de joburi și companii (crește zilnic). Basic Auth activ. Schema are multe câmpuri (de la diverși scrapers), dar cele definitorii sunt cele de mai sus.

## Arhitectură rețea

| Domeniu | IP public | Target local |
|---------|-----------|-------------|
| `solr.peviitor.ro` (PROD) | `86.122.35.88` | Server PROD extern |
| `testsolr.peviitor.ro` | `86.122.35.88` → `192.168.1.130:8983` | SOLR test |
| `test.peviitor.ro` | `86.122.35.88` → `192.168.1.130:8081` | API test (BFF) + Swagger UI |
| `api.peviitor.ro` (PROD) | - | API PROD extern |

Toate domeniile sunt aliasuri pentru `zimbor.go.ro`. Un reverse proxy extern (nginx) face rutarea:
- `/solr` → `192.168.1.130:8983`
- `/v1/`, `/v0/`, `/swagger-ui/` → `192.168.1.130:8081` (API + Swagger UI)
- `/` → site-ul de documentație

### Observație importantă
Căile API NU au prefixul `/api`. Swagger.json definește server URL direct pe `https://test.peviitor.ro/v1`, nu `https://test.peviitor.ro/api/v1`. Proxy-ul extern nu prefixează cu `/api`.

## Hardware — Raspberry Pi 4 (test server)

- CPU: ARM Cortex-A72, 4 nuclee, 64-bit
- RAM: 1.8 GB
- Swap: 3.8 GB (1.8 GB zram + 2 GB swapfile pe SD)
- Storage: 58 GB total (~46 GB liber)
- OS: Debian 13 "trixie" (aarch64), kernel 6.12
- Docker 29.5.2 instalat și funcțional
- IP local: `192.168.1.130`

## Limitări hardware (de reținut)
- **RAM limitată** (1.8 GB) — Java/SOLR e hungry. Monitorizează cu `docker stats`.
- **Swap mixt** (zram + SD card) — suficient pentru test, dar scrisul pe SD e lent.
- **Storage** ~46GB liber momentan, de monitorizat.
- **ARM64** — imaginile Docker trebuie să suporte multi-arch (solr:latest suportă).

## Status instalare — ce s-a făcut

1. ✅ **Docker** — instalat (nu era pe sistem), user adăugat în grupul docker
2. ✅ **SOLR 10.0.0** — container `peviitor-solr` pe port 8983, imagine `solr:latest`
3. ✅ **Core `job`**:
   - Creat cu `solr-precreate`, apoi editat `managed-schema.xml` să aibă `url` ca uniqueKey
   - Câmpuri adăugate: url, title, company, cif, location, tags, workmode, salary, date, vdate, expirationdate, status
   - copyField în `_text_` pentru: url, title, company, location, tags, workmode, salary
   - Suggester activat (vezi secțiunea Suggest)
4. ✅ **Core `company`**:
   - Creat din configsetul `_default` (uniqueKey = `id`)
   - Câmpuri adăugate: company, brand, group, status, location, website, career, lastScraped, scraperFile
   - copyField în `_text_` pentru: company, location, website, brand, group
5. ✅ **Test inserare documente din PROD**:
   - 1 document `job` → inserat și regăsit corect
   - 1 document `company` → inserat și regăsit corect
6. ✅ **Basic Auth SOLR** — activat cu `${{ secrets.SOLR_USER }}` / `${{ secrets.SOLR_PASS }}`
7. ✅ **API (BFF)** — container `peviitor-api` pe port 8081
   - Imagine custom `peviitor-api:latest` bazată pe `php:8.2-apache-bookworm` (ARM64)
   - Codul din `peviitor-ro/api` branch master, montat volume la `/var/www/html`
   - `api.env` configurează `PROD_SERVER=host.docker.internal:8983` (SOLR local)
   - Endpoint-uri funcționale: `/v1/jobs/`, `/v1/total/`, `/v1/company/`, `/v1/search/`, `/v1/suggest/`, `/v1/random/`
   - **v0** reparat: core `jobs` → `job` (9 fișiere editate)
   - Documente: 1 job, 1 company (din SOLR local)
   - Expus extern prin `https://test.peviitor.ro/v1/jobs/`
8. ✅ **Swagger UI** — integrat în același container API (fără container separat)
   - Fișiere Swagger UI în `/home/sebi/peviitor/api/swagger-ui/` (volume-mountate la `/var/www/html/swagger-ui/`)
   - URL local: `http://localhost:8081/swagger-ui/`
   - URL extern: `https://test.peviitor.ro/swagger-ui/`
   - Configurat cu `url: "/v1/swagger.json"` (cale relativă — funcționează same-origin atât local cât și extern)
   - CORS: endpoint-urile v1 au `Access-Control-Allow-Origin: *` în PHP
   - Swagger UI descarcă spec-ul din `/v1/swagger.json`
9. ✅ **Suggest (Suggester Solr)** — configurat pe core-ul `job`:
   - Componentă: `solr.SuggestComponent` cu numele `suggest`
   - Suggester: `jobTitleSuggester` (FuzzyLookupFactory + DocumentDictionaryFactory)
   - Câmp sursă: `title` (tip `text_general`)
   - **buildOnCommit: true** — se reconstruiește la fiecare commit
   - **buildOnStartup: false** — nu se construiește automat la pornire
   - Configurat via Config API (nu direct în solrconfig.xml) → stocat în `configoverlay.json`
   - Endpoint PHP: `/v1/suggest/?q=...` → proxy către `/solr/job/suggest`
   - Pentru rebuild manual: `suggest.build=true` (trimis automat de endpoint)
10. ✅ **Frontend (search-engine)** — `peviitor-ro/search-engine` clonat și construit
    - Repo la `/home/sebi/peviitor/search-engine/`, build-ul în `dist/`
    - Build custom `--mode qa` cu `.env.qa.local` care punctează la API-ul local:
      - `VITE_API_URL=https://test.peviitor.ro/v1/search/`
      - `VITE_API_LOGO=https://test.peviitor.ro/v1/logo/`
      - `VITE_API_COMPANIES=https://test.peviitor.ro/v1/company/`
      - `VITE_API_SUGGEST=https://test.peviitor.ro/v1/suggest/`
      - `VITE_API_TOTAL=https://test.peviitor.ro/v1/total/`
    - Servit la rădăcină (`/`) de același container Apache pe port 8081
    - API paths (`/v1/*`, `/v0/*`, `/swagger-ui/`) rămân funcționale via `AliasMatch`
    - SPA routing: toate path-urile nematchuite cad pe `/index.html`
11. ✅ **MCP Chrome DevTools** — configurat în `~/.config/opencode/opencode.jsonc`
    - Rulează `npx chrome-devtools-mcp --headless` cu Chromium 148
    - Permite testare dinamică a paginii direct din opencode
12. Scripturile de instalare SOLR sunt în `ApacheSOLR/pi/` din repo

## Acces

| Serviciu | Intern (Pi4) | Extern |
|----------|-------------|--------|
| Frontend (search-engine) | `http://localhost:8081/` | `https://test.peviitor.ro/` |
| SOLR | `http://localhost:8983/solr` | `https://testsolr.peviitor.ro/solr` |
| API v1 | `http://localhost:8081/v1/jobs/` | `https://test.peviitor.ro/v1/jobs/` |
| API v0 | `http://localhost:8081/v0/jobs/` | `https://test.peviitor.ro/v0/jobs/` |
| Swagger UI | `http://localhost:8081/swagger-ui/` | `https://test.peviitor.ro/swagger-ui/` |
| Suggest | `http://localhost:8081/v1/suggest/?q=sofer` | `https://test.peviitor.ro/v1/suggest/?q=sofer` |
| Swagger spec | `http://localhost:8081/v1/swagger.json` | `https://test.peviitor.ro/v1/swagger.json` |

Autentificare SOLR: `${{ secrets.SOLR_USER }}` / `${{ secrets.SOLR_PASS }}`

## Configurare api.env

`api.env` din acest folder este un **template sigur de comis** (valori goale pentru credentiale).
Pentru a rula local, completează `SOLR_USER` și `SOLR_PASS` în fișier sau, mai bine,
păstrează un `api.env` cu credentiale reale în afara acestui repo
(ex: `/home/sebi/peviitor/config/api.env`) și setează path-ul absolut în `docker-compose.yml`.

Structura fișierului:

```
PROD_SERVER=host.docker.internal:8983
LOCAL_SERVER=host.docker.internal:8983
BACK_SERVER=host.docker.internal:8983
SOLR_USER=
SOLR_PASS=
```

**Nu comita api.env cu credentiale reale în Git.**

## Detalii configurare SOLR Suggest

### Cum funcționează
- Configurarea e aplicată via **Config API** SOLR și stocată în `configoverlay.json`
- Nu trebuie editat manual `solrconfig.xml`
- Suggester-ul `jobTitleSuggester` face fuzzy matching pe titlurile joburilor

### Configurare (echivalent în Config API)
```json
{
  "add-searchcomponent": {
    "name": "suggest",
    "class": "solr.SuggestComponent",
    "suggester": {
      "name": "jobTitleSuggester",
      "lookupImpl": "FuzzyLookupFactory",
      "dictionaryImpl": "DocumentDictionaryFactory",
      "field": "title",
      "suggestAnalyzerFieldType": "text_general",
      "buildOnCommit": "true",
      "buildOnStartup": "false"
    }
  }
}
```
```json
{
  "add-requesthandler": {
    "name": "/suggest",
    "class": "solr.SearchHandler",
    "startup": "lazy",
    "defaults": {
      "suggest": "true",
      "suggest.dictionary": "jobTitleSuggester",
      "suggest.count": "10"
    },
    "components": ["suggest"]
  }
}
```

### Rebuild manual (dacă e nevoie)
```bash
curl -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/job/suggest?suggest=true&suggest.build=true&suggest.dictionary=jobTitleSuggester&suggest.q=a&wt=json"
```
Endpoint-ul PHP (`/v1/suggest/`) trimite automat `suggest.build=true` la fiecare request.

## Fișiere în proiect (peviitor_test_env/)

Acest folder conține **doar instrucțiuni și template-uri** — nici un fișier live cu credentiale.

| Fișier | Rol |
|--------|-----|
| `INSTRUCTIONS.md` | Acest fișier — prompt AI |
| `install_solr_test.sh` | Script re-instalare SOLR complet |
| `docker-compose.yml` | Referință orchestrator (path-urile指向 în afara folderului) |
| `Dockerfile.api` | Imagine PHP-Apache custom (ARM64) |
| `api.env` | Template configurare SOLR (valori goale — completează local) |
| `apache-frontend.conf` | Config Apache: frontend la `/`, API la `/v1/*`, `/v0/*`, `/swagger-ui/` |
| `TESTS.md` | Instrucțiuni testare |
| `SECURITY.md` | Politica de securitate pentru credentiale |

Configurarea live cu credentiale reale: `/home/sebi/peviitor/config/api.env`

## Comenzi utile

```bash
# Status containere
docker ps | grep -E "peviitor-solr|peviitor-api"

# Logs
docker logs peviitor-api --tail 50
docker logs peviitor-solr --tail 50

# Query API
curl -s http://localhost:8081/v1/jobs/
curl -s http://localhost:8081/v1/total/
curl -s http://localhost:8081/v1/company/?cif=12477373
curl -s http://localhost:8081/v1/search/?q=sofer
curl -s http://localhost:8081/v1/suggest/?q=sofer
curl -s http://localhost:8081/v1/random/
curl -s http://localhost:8081/v0/jobs/
curl -s http://localhost:8081/v0/total/

# Swagger UI
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/swagger-ui/

# Query SOLR local
curl -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/job/select?q=*:*&wt=json"
curl -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/company/select?q=*:*&wt=json"
curl -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/job/suggest?suggest=true&suggest.dictionary=jobTitleSuggester&suggest.q=sofer&wt=json"

# Frontend (build cu qa env)
cd /home/sebi/peviitor/search-engine && npm run build:qa

# Rebuild API image (după modificări Dockerfile sau Apache config)
cd ~/opencode-ai/peviitor_test_env && docker compose build api

# Restart API (după rebuild frontend, fără rebuild imagine)
cd ~/opencode-ai/peviitor_test_env && docker compose restart api

# Oprire / pornire toate serviciile
cd ~/opencode-ai/peviitor_test_env && docker compose down
cd ~/opencode-ai/peviitor_test_env && docker compose up -d

# Inserare document in SOLR
curl -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} -X POST "http://localhost:8983/solr/job/update?commit=true" \
  -H "Content-Type: application/json" \
  -d '[{"url": "...", "title": "...", "company": "..."}]'
```

## Principii generale

1. **Ascultă cu atenție instrucțiunile utilizatorului** — fiecare cerință contează.
2. **NU salva credentiale în fișiere comittate** — doar locale, în `.env` sau în `~/.config/`.
3. **Confirmă în scurt** ce ai făcut și ce urmează.
4. **Când nu ești sigur, întreabă înainte să acționezi.**

## Flow de lucru

- Așteaptă instrucțiuni pas cu pas.
- Scripturile noi trebuie să fie **compatibile cu Pi4 (ARM64, Docker, resurse limitate)**.

## Notă importantă

Acest folder (`peviitor_test_env/`) conține **doar instrucțiuni și template-uri**. Nici un fișier live (api.env, configurări runtime) nu locuiește aici. Toate configurațiile cu credentiale reale sunt în `/home/sebi/peviitor/config/` sau în afara acestui folder.
