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

| Field      | Type   | Required | Description |
|------------|--------|----------|-------------|
| id         | string | Yes      | MD5 hash of `job_link` (ex: "a1b2c3d4e5f6..."). |
| job_link   | string | Yes      | Full URL to the job detail page. |
| job_title  | string | Yes      | Exact position title. |
| company    | string | Yes      | Name of the hiring company. Real name. Full name. not just a brand or a code. Legal name. |
| location   | string | No       | Location or detailed address. |
| tags       | array  | No       | Tag-uri skills/educație/experiență. |
| workmode   | string | No       | "remote", "on-site", "hybrid". |



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

