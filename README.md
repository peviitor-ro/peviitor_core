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
| company    | string | Yes      | Name of the hiring company. |
| location   | string | No       | Location or detailed address. |

