# peviitor_core

Here is the core of the peviitor project.

Mostly, it's about **data** and the **quality of data**. But it's also about getting the data you are searching for using a full-text indexed search engine.

## Plugins
BFF API, UI, scrapers, and manual data validator will be considered as **plugins** for the peviitor core project.

## Project Scope
- Security and procedures related to ways of working will be part of the project.
- How to connect and how to use it will be captured in **documentation**.
- All pull requests will be **documented**.
- Project is **OPEN SOURCE**.
- Each data and type of data will be **fully documented**.
- peviitor core is not a closed project but an **extensible** one.

## Key Benefits
**Performance, reliability, recovery from disaster, scalability, and validity** are the most valuable benefits this project delivers.


## Job Model Schema

| Field          | Type   | Required | Description |
|----------------|--------|----------|-------------|
| job_link       | string | Yes      | Full URL to the job detail page. |
| id             | string | Yes      | MD5 hash of `job_link` (ex: "a1b2c3d4e5f6..."). |
| job_title      | string | Yes      | Exact position title. |
| company        | string | Yes      | Name of the hiring company. Real name. Full name. not just a brand or a code. Legal name. |
| location       | string | No       | Location or detailed address. |
| tags           | array  | No       | Tag-uri skills/educație/experiență. |
| workmode       | string | No       | "remote", "on-site", "hybrid". |
| date           | date   | Yes      | Data scrape/indexare (ISO8601). |
| validation     | string | Yes      | "scraped", "tested", "published", "verified". |
| vdate          | date   | No       | Verified date (ISO8601). |
| expirationdate | date   | No       | Data expirare estimată job. |
| salary         | string | No       | Interval salarial + currency (ex: "5000-8000 RON", "4000 EUR"). |




## Company Model Schema

| Field     | Type   | Required | Description |
|-----------|--------|----------|-------------|
| id        | string | Yes      | CIF/CUI al firmei (ex: "12345678"). |
| vat       | string | Yes      | CUI cu prefix RO dacă plătitor TVA (ex: "RO12345678"). |
| name      | string | Yes      | Denumire exactă pentru job matching. |
| address   | string | Yes      | Adresa sediului social completă. |
| status    | string | Yes      | Stare: "activ", "suspendat", "inactiv", "radiat". |
| county    | string | No       | Județ (ex: "Bucuresti", "Ilfov"). |
| city      | string | No       | Localitate (ex: "Sector 1", "Pipera"). |
| email     | string | No       | Email oficial firmă (ex: "hr@company.ro"). |
| phone     | string | No       | Număr telefon firmă (ex: "0212345678", "+40721234567"). |

## Auth Model Schema

| Field     | Type     | Required | Description |
|-----------|----------|----------|-------------|
| email     | string  | Yes      | MD5 hash al emailului (ex: "d41d8cd98f00b204e9800998ecf8427e"). |
| token     | string  | No       | OTP token temporar (6 digits, ex: "123456"). |
| companies | array   | No       | Array CIF-uri companii accesibile (ex: ["12345678", "87654321"]). |

### Job Model Rules

1. **id** must be exactly MD5(job_link) - 32 hex chars lowercase
2. **job_link** must be valid HTTP/HTTPS URL, canonical job detail page
3. **job_title** max 200 chars, no HTML, trimmed whitespace, **DIACRITICS ACCEPTED** (ăâîșțĂÂÎȘȚ)
4. **company** must match exactly Company.name (case insensitive, **DIACRITICS PRESERVED**)
5. **date** = UTC ISO8601 timestamp of scrape (ex: "2026-01-18T10:00:00Z")
6. **validation** starts "scraped", progresses: scraped → tested → published → verified
7. **vdate** set only when validation="verified"
8. **expirationdate** = vdate + 30 days max, or extract from job page
9. **salary** format: "MIN-MAX CURRENCY" or "negotiable CURRENCY"
10. **tags** lowercase, max 20 entries, standardized values only, **NO DIACRITICS**
11. **workmode** only: "remote", "on-site", "hybrid"
12. **location** Romanian cities/addresses, **DIACRITICS ACCEPTED** (ex: "București", "Cluj-Napoca")


### Company Model Rules

1. **id** = exact CIF/CUI 8 digits (no RO prefix)
2. **vat** = "RO" + id if TVA registered, else null
3. **name** = legal name from Registrul Comerțului exact match, **DIACRITICS REQUIRED** (ex: "Tehnologia Informației")
4. **address** Romanian format, **DIACRITICS ACCEPTED** (ex: "Str. Ștefan cel Mare")
5. **status** only: "activ", "suspendat", "inactiv", "radiat"
6. **county** Romanian județe, **DIACRITICS ACCEPTED** (ex: "București", "Ilfov")
7. **city** Romanian localități, **DIACRITICS ACCEPTED**
8. **phone** RO format: "02x..." or "+407xx..." (14 chars max)
9. **email** valid format, domain MX record exists

### Auth Model Rules

1. **email** = MD5(email_lowercase) 32 hex chars
2. **token** = 6 digits numeric OTP, expires 10min
3. **companies** = array valid CIF from Company model only


### SOLR/OpenSearch Note

analyzer: "romanian" preserves diacritics ȘȚĂÂÎ
search: "Bucuresti" matches "București" automatically

