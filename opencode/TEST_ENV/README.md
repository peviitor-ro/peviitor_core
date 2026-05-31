# TEST_ENV — Peviitor Test Environment (Raspberry Pi 4)

Stack complet de test pentru platforma peviitor, rulat pe un Raspberry Pi 4 local.

## Arhitectură

```
Internet ──→ Reverse Proxy (nginx, extern)
                  │
          ┌───────┴───────┐
          ↓               ↓
    test.peviitor.ro    testsolr.peviitor.ro
    (port 8081)         (port 8983)
          │               │
    ┌─────┴──────┐       ┌┴─────┐
    │  Frontend  │       │ Solr │
    │  (React)   │       │10.0.0│
    │  /v1/* API │       │ Basic│
    │  SwaggerUI │       │ Auth │
    └────────────┘       └──────┘
```

## Endpoint-uri

### Frontend
| URL | Descriere |
|---|---|
| `https://test.peviitor.ro/` | Motorul de căutare (React, Vite) |

### API (BFF — PHP)

Toate endpoint-urile sunt sub `https://test.peviitor.ro/`:

| Endpoint | Exemple răspuns | Descriere |
|---|---|---|
| `/v1/search/?q=sofer&city=Bucuresti` | `{"response":{"numFound":1,"docs":[...]}}` | Căutare full-text joburi |
| `/v1/total/` | `{"total":{"jobs":1,"companies":1}}` | Total joburi și companii |
| `/v0/total/` | `{"total":{"jobs":1,"companies":0}}` | Total (v0, doar `job` core) |
| `/v1/jobs/` | `{"response":{"numFound":1,"docs":[...]}}` | Listare toate joburile |
| `/v1/company/?cif=12477373` | `{"company":{"id":"12477373",...}}` | Detalii companie după CIF |
| `/v1/companies/?rows=100` | `{"total":1,"companies":[...]}` | Listare companii |
| `/v1/suggest/?q=sofer` | `{"suggestions":[{"term":"SOFER DE..."}]}` | Sugestii titluri joburi (fuzzy) |
| `/v1/logo/` | `{"total":1,"logos":[{"company":"...","logo":"..."}]}` | Logo-uri companii |
| `/v1/random/` | `{"url":"...","title":"..."}` | Job aleator |
| `/v1/swagger.json` | OpenAPI 3.0 spec | Specificația Swagger |
| `/swagger-ui/` | UI interactiv | Interfață Swagger pentru testare |

### Solr
| URL | Descriere |
|---|---|
| `https://testsolr.peviitor.ro/solr/` | Solr admin UI (Basic Auth) |
| `https://testsolr.peviitor.ro/solr/job/select?q=*:*` | Core `job` |
| `https://testsolr.peviitor.ro/solr/company/select?q=*:*` | Core `company` |

Autentificare Solr: user `solr`.

## Date

În prezent sunt inserate:
- **1 job** (exemplu: "SOFER DE AUTOTURISME SI CAMIONETE")
- **1 companie** (exemplu: "FLEISCHPARTY SRL")

Suggest-ul functionează cu `FuzzyLookupFactory` pe câmpul `title`.

## Resurse hardware (Pi4)

- CPU: ARM Cortex-A72, 4 nuclee
- RAM: 1.8 GB (+ 3.8 GB swap: zram + swapfile)
- Storage: 58 GB SD (44 GB liber)
- OS: Debian 13 "trixie" (aarch64)
- Docker 29.5.2

## Cum rulezi

```bash
cd opencode/TEST_ENV
docker compose up -d
```

Pentru rebuild frontend:
```bash
cd /home/sebi/peviitor/search-engine
npm run build:qa
docker compose restart api
```

## Credentiale

Fișierul `api.env` din acest folder este un **template sigur** (valori goale).
Credentialele reale sunt în afara repo-ului la `/home/sebi/peviitor/config/api.env`.

**Nu comita api.env cu credentiale reale în Git.**

Vezi `SECURITY.md` pentru detalii.
