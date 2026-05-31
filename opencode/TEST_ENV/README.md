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

## Toate linkurile

### Frontend
- `https://test.peviitor.ro/` — motorul de căutare (React)

### API (BFF — PHP) — toate sub `https://test.peviitor.ro/`
- `https://test.peviitor.ro/v1/search/?q=sofer` — căutare full-text joburi
- `https://test.peviitor.ro/v1/jobs/` — listare toate joburile
- `https://test.peviitor.ro/v1/total/` → `{"total":{"jobs":1,"companies":1}}` — total joburi și companii
- `https://test.peviitor.ro/v0/total/` → `{"total":{"jobs":1,"companies":0}}` — total (v0, doar core `job`)
- `https://test.peviitor.ro/v1/company/?cif=12477373` — detalii companie după CIF
- `https://test.peviitor.ro/v1/companies/?rows=100` — listare companii
- `https://test.peviitor.ro/v1/suggest/?q=sofer` — sugestii titluri joburi (fuzzy)
- `https://test.peviitor.ro/v1/logo/` — logo-uri companii
- `https://test.peviitor.ro/v1/random/` — job aleator
- `https://test.peviitor.ro/v1/swagger.json` — specificația OpenAPI 3.0
- `https://test.peviitor.ro/swagger-ui/` — interfață Swagger interactivă

### Solr — toate sub `https://testsolr.peviitor.ro/solr/` (Basic Auth: user `solr`)
- `https://testsolr.peviitor.ro/solr/` — admin UI
- `https://testsolr.peviitor.ro/solr/job/select?q=*:*` — core `job`
- `https://testsolr.peviitor.ro/solr/company/select?q=*:*` — core `company`

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
