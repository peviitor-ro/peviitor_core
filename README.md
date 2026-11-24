# peviitor_core

Here is the core of the peviitor project.

Mostly, it's about **data** and the **quality of data**. But it's also about getting the data you are searching for using a full-text indexed search engine.
Workflows, pipelines and code that is validating the rules, keeping the index up-to-date is also part of peviitor_core.



## Job Model Schema

| Field          | Type     | Required | Description and rules |
|----------------|----------|----------|----------------------|
| url            | string   | Yes      | Full URL to the job detail page. unique. **url** must be valid HTTP/HTTPS URL, canonical job detail page|
| title          | string   | Yes      | Exact position title. **title** max 200 chars, no HTML, trimmed whitespace, **DIACRITICS ACCEPTED** (ăâîșțĂÂÎȘȚ)|
| company        | string   | No       | Name of the hiring company. Real name. Full name. Use uppercase always. not just a brand or a code. Legal name.  **company** must match exactly Company.name (case insensitive, **DIACR[...]
| cif            | string   | No       | CIF/CUI. Due to the fact that Systematic SRL exist with same name in 3 different counties Bihor, Arad, Timis |
| location       | string[] | No       | Location or detailed address.  **location** Romanian cities/addresses, **DIACRITICS ACCEPTED** (ex: "București", "Cluj-Napoca"). multi-valued, stored as array|
| tags           | string[] | No       | Tag-uri skills/educație/experiență. **tags** lowercase, max 20 entries, standardized values only, **NO DIACRITICS**|
| workmode       | string   | No       | "remote", "on-site", "hybrid".  **workmode** only: "remote", "on-site", "hybrid"|
| date           | date     | No       | Data scrape/indexare (ISO8601). **date** = UTC ISO8601 timestamp of scrape (ex: "2026-01-18T10:00:00Z")|
| status         | string   | No       | "scraped", "tested", "published", "verified". **status** starts "scraped", progresses: scraped → tested → published → verified|
| vdate          | date     | No       | Verified date (ISO8601). **vdate** set only when validation="verified"|
| expirationdate | date     | No       | Data expirare estimată job.  **expirationdate** = vdate + 30 days max, or extract from job page|
| salary         | string   | No       | Interval salarial + currency (ex: "5000-8000 RON", "4000 EUR"). **salary** format: "MIN-MAX CURRENCY" ; must be a string not an array.|

## Job Status Flow
Job status follows this progression: `scraped` → (`tested` OR `verified`) → `published`
| Status | Meaning | When to Use |
|--------|---------|-------------|
| `scraped` | Newly scraped, not validated yet | Default after scraping |
| `tested` | URL works, job exists but couldn't extract full details | Page blocked by CAPTCHA, didn't load properly, missing salary/tags/workmode |
| `verified` | Fully scraped with all details | All fields extracted: company, cif, salary, tags, workmode |
| `published` | Imported from jobs core | Old validator flow - jobs imported to main job index |
Notes:
- tested jobs can be re-validated later when more data becomes available
- vdate (verified date) is set only when status becomes tested or verified
- Jobs with status verified are considered valid and ready for publication

> **Note**: Fields marked as `string[]` are multi-valued arrays. In SOLR/OpenSearch these are stored as arrays (e.g., `["București", "Cluj-Napoca"]`).

## Company Model Schema

| Field     | Type     | Required | Description |
|-----------|----------|----------|-------------|
| id        | string   | Yes      | CIF/CUI of the company (e.g. "12345678"). **id** = exact CIF/CUI 2-13 digits (no RO prefix). |
| company   | string   | Yes      | Exact name for job matching. **company** = legal name from Trade Register, **DIACRITICS REQUIRED** (e.g. "Tehnologia Informației"). Use uppercase|
| brand     | string   | No       | Commercial brand name (e.g. "ORANGE", "EPAM"). Used for display purposes. |
| group     | string   | No       | Parent company group (e.g. "Orange Group", "EPAM Systems"). |
| status    | string   | No       | Status: "activ", "suspendat", "inactiv", "radiat". If company status is not active, remove jobs; also remove company. **status** only: "activ", "suspendat", "inactiv", "radiat". |
| location  | string[] | No       | Location or detailed address. **location** Romanian cities/addresses, **DIACRITICS ACCEPTED** (e.g. "București", "Cluj-Napoca"). multi-valued, stored as array; location [
{ "judet": "Bucuresti",
  "localitate": "Cluj-Napoca",
  "adresa": " str. Mehedinti 88 sc 5, Cluj-Napoca"
}] |
| website   | string[] | No       | Official company website. **website** must be a valid HTTP/HTTPS URL, preferably canonical, without trailing slash (e.g. "https://www.example.ro"). multi-valued, stored as array |
| career    | string[] | No       | Official company career page. **career** must be a valid HTTP/HTTPS URL, preferably canonical, without trailing slash, pointing to the jobs/careers section (e.g. "https://www.example.ro/careers"). multi-valued, stored as array |
| lastScraped | string | No       | Date of last scrape in ISO8601 format (e.g. "2026-02-20"). Used for tracking. |
| scraperFile | string | No       | Name of the scraper file used (e.g. "epam.md", "orange.md"). Used for reference. |


> **Note**: Fields marked as `string[]` are multi-valued arrays. In SOLR/OpenSearch these are stored as arrays (e.g., `["https://example.com", "https://careers.example.com"]`).

## Technologies

### Search & Indexing Engines

| Technology | Status | Use Case | Notes |
|------------|--------|----------|-------|
| **Apache SOLR** | ✅ Primary | Production indexing, diacritics RO, complex schemas | Job/Company/Auth models, cron integration |
| **OpenSearch** | ✅ Primary | SOLR alternative, AWS compatible | Same schema, managed hosting |
| **Elasticsearch** | ⚠️ Secondary | Legacy compatibility | Existing peviitor scrapers |
| **Typesense** | 🚀 MVP/Prototype | Ultra-fast UI search (<50ms) | Typo-tolerant, developer friendly |

## Notes
- Project is **OPEN SOURCE**.
- Security and procedures related to ways of working will be part of the project.
- How to connect and how to use it will be captured in **documentation**.
- All pull requests will be **documented**.
- peviitor core is not a closed project but an **extensible** one.



## Key Benefits
**Performance, reliability, recovery from disaster, scalability, and validity** are the most valuable benefits this project delivers.

### SOLR/OpenSearch Note

* analyzer: "romanian" preserves diacritics ȘȚĂÂÎ
* search: "Bucuresti" matches "București" automatically

**Purpose**: Remove expired job listings automatically

**Schedule**: Daily @ 02:00 AM EET
**Logic**: 
- DELETE jobs WHERE `expirationdate` < NOW() AND `validation`="verified"
- SOLR/OpenSearch: `delete_by_query` range query on `expirationdate`

**Purpose**: Validate job URLs are still active **DAILY**

**Schedule**: Daily @ 06:00 AM EET  
**Workflow**:
1. SELECT jobs WHERE `validation`="verified" AND `date` > 1 day ago
2. Parallel HTTP HEAD requests (max 1000 concurrent) to `job_link`
3. **404** → DELETE job immediately
4. **200 OK** → Parse content for "expirat"/"ocupat"/"închis"/"no longer available"/"filled"
5. **Invalid content** → SET `validation`="tested", schedule recheck in 24h
6. **Valid** → UPDATE `validation`="verified", `vdate`=NOW()
**Max batch**: 50k jobs/day, prioritize newest first


## Plugins

The following components are considered **plugins** for the peviitor core project:

- BFF API — Backend-for-Frontend API layers that tailor data and endpoints for different clients.
- UI — Web or mobile user interfaces and frontend components.
- Scrapers — Automated data collectors that fetch and normalize job and company data.
- Manual data validator — Tools or interfaces used by humans to validate and correct data.
- Integrations — Connectors to external services (analytics, exporters, auth providers, etc.).

#SOLR
prod: https://solr.peviitor.ro
