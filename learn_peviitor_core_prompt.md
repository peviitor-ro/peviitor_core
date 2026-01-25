

Learn those models:

## Job Model Schema

| Field          | Type   | Required | Description and rules |
|----------------|--------|----------|-------------|
| url            | string | Yes      | Full URL to the job detail page. unique. **url** must be valid HTTP/HTTPS URL, canonical job detail page|
| title          | string | Yes      | Exact position title. **title** max 200 chars, no HTML, trimmed whitespace, **DIACRITICS ACCEPTED** (ăâîșțĂÂÎȘȚ)|
| company        | string | No       | Name of the hiring company. Real name. Full name. not just a brand or a code. Legal name.  **company** must match exactly Company.name (case insensitive, **DIACR[...]
| cif            | string | No       | CIF/CUI. Due to the fact that Systematic SRL exist with same name in 3 different counties Bihor, Arad, Timis |
| location       | string | No       | Location or detailed address.  **location** Romanian cities/addresses, **DIACRITICS ACCEPTED** (ex: "București", "Cluj-Napoca")|
| tags           | array  | No       | Tag-uri skills/educație/experiență. **tags** lowercase, max 20 entries, standardized values only, **NO DIACRITICS**|
| workmode       | string | No       | "remote", "on-site", "hybrid".  **workmode** only: "remote", "on-site", "hybrid"|
| date           | date   | No       | Data scrape/indexare (ISO8601). **date** = UTC ISO8601 timestamp of scrape (ex: "2026-01-18T10:00:00Z")|
| status         | string | No       | "scraped", "tested", "published", "verified". **status** starts "scraped", progresses: scraped → tested → published → verified|
| vdate          | date   | No       | Verified date (ISO8601). **vdate** set only when validation="verified"|
| expirationdate | date   | No       | Data expirare estimată job.  **expirationdate** = vdate + 30 days max, or extract from job page|
| salary         | string | No       | Interval salarial + currency (ex: "5000-8000 RON", "4000 EUR"). **salary** format: "MIN-MAX CURRENCY" or "negotiable CURRENCY"|




## Company Model Schema

| Field     | Type   | Required | Description |
|-----------|--------|----------|-------------|
| id        | string | Yes      | CIF/CUI of the company (e.g. "12345678"). **id** = exact CIF/CUI 8 digits (no RO prefix). |
| company   | string | Yes      | Exact name for job matching. **company** = legal name from Trade Register, **DIACRITICS REQUIRED** (e.g. "Tehnologia Informației"). |
| status    | string | No       | Status: "activ", "suspendat", "inactiv", "radiat". If company status is not active, remove jobs; also remove company. **status** only: "activ", "suspendat", "inactiv", "radiat". |
| location  | string | No       | Location or detailed address. **location** Romanian cities/addresses, **DIACRITICS ACCEPTED** (e.g. "București", "Cluj-Napoca"). |
| website   | string | No       | Official company website. **website** must be a valid HTTP/HTTPS URL, preferably canonical, without trailing slash (e.g. "https://www.example.ro"). |
| career   | string | No       | Official company career page. **career** must be a valid HTTP/HTTPS URL, preferably canonical, without trailing slash, pointing to the jobs/careers section (e.g. "https://www.example.ro/careers"). |


we need to extract a JSON to add in Apache SOLR the company and all jobs will be also extracted in JSON format as array of objects.
JSON for company will go into company SOLR core
JSON for jobs will go into job SOLR core