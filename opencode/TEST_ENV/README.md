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

| Serviciu | URL |
|---|---|
| Frontend | `https://test.peviitor.ro/` |
| API căutare | `https://test.peviitor.ro/v1/search/?q=sofer` |
| API joburi | `https://test.peviitor.ro/v1/jobs/` |
| API total (v1) | `https://test.peviitor.ro/v1/total/` → `{"total":{"jobs":1,"companies":1}}` |
| API total (v0) | `https://test.peviitor.ro/v0/total/` → `{"total":{"jobs":1,"companies":0}}` |
| API companie | `https://test.peviitor.ro/v1/company/?cif=12477373` |
| API companii | `https://test.peviitor.ro/v1/companies/?rows=100` |
| API suggest | `https://test.peviitor.ro/v1/suggest/?q=sofer` |
| API logo | `https://test.peviitor.ro/v1/logo/` |
| API random | `https://test.peviitor.ro/v1/random/` |
| Swagger spec | `https://test.peviitor.ro/v1/swagger.json` |
| Swagger UI | `https://test.peviitor.ro/swagger-ui/` |
| Solr admin | `https://testsolr.peviitor.ro/solr/` (Basic Auth) |
| Solr core job | `https://testsolr.peviitor.ro/solr/job/select?q=*:*` |
| Solr core company | `https://testsolr.peviitor.ro/solr/company/select?q=*:*` |

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
