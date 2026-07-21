# Apache Solr on Raspberry Pi — Installation Guide

This directory contains scripts to install and run **Apache Solr** inside a Docker container on a **Raspberry Pi** (aarch64/ARM64).

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4x ARM Cortex-A72+ | 4x Cortex-A76 (Pi5) |
| **RAM** | 4 GB | **8+ GB** |
| **Storage** | 10 GB free | 20 GB+ free |
| **OS** | Raspberry Pi OS (Debian-based) | 64-bit |

This setup is tested on **Raspberry Pi 5 with 16 GB RAM**.

## Scripts Overview

| # | Script | Purpose |
|---|--------|---------|
| 000 | `000_tools.sh` | Clean old Solr Docker artifacts, install Docker (idempotent) |
| 001 | `001_apache_solr.sh` | Pull `solr:latest`, start container on port **8983** with 2G heap + auto-restart |
| 002 | `002_upgrade_solr.sh` | Stop container, pull fresh image, restart (same config) |
| 003 | `003_recreate-job-core.sh` | Delete and recreate the `job` core |
| 004 | `004_url_uniquekey_pi.sh` | Set `url` as the uniqueKey for the `job` core via Schema API |
| 005 | `005_schema_jobs_pi.sh` | Add all job schema fields + SuggestComponent for autocomplete |
| 006 | `006_recreate_company_core_pi.sh` | Delete and recreate the `company` core |
| 007 | `007_schema_company_pi.sh` | Add all company schema fields |
| 008 | `008_enable_solr_basic_auth_pi.sh` | Enable Basic Auth (`solr` / `SolrRocks`) |
| 009 | `009_auto_update_solr.sh` | Check for newer `solr:latest` image digest and auto-upgrade |
| 010 | `010_setup_cron.sh` | Install daily cron at **3:00 AM** to run script 009 |

## Quick Install

```bash
# 1. Clone the repo
git clone https://github.com/peviitor-ro/peviitor_core.git
cd peviitor_core/ApacheSOLR/pi

# 2. Make all scripts executable
chmod +x *.sh

# 3. Run the full install (runs 000 → 010 in sequence)
./install.sh
```

### Step-by-Step (alternative)

```bash
# Phase 1: Install Docker
./000_tools.sh
newgrp docker   # or logout/login to activate docker group

# Phase 2: Start Solr
./001_apache_solr.sh

# Phase 3: Configure job core
./003_recreate-job-core.sh
./004_url_uniquekey_pi.sh
./005_schema_jobs_pi.sh

# Phase 4: Configure company core
./006_recreate_company_core_pi.sh
./007_schema_company_pi.sh

# Phase 5: Enable authentication
./008_enable_solr_basic_auth_pi.sh

# Phase 6: Set up auto-updates (optional)
./009_auto_update_solr.sh
./010_setup_cron.sh
```

## Configuration Details

### Solr Container

| Setting | Value |
|---------|-------|
| Image | `solr:latest` (multi-arch, ARM64 native) |
| Container name | `peviitor-solr` |
| Port | 8983 |
| Data volume | `~/peviitor/solr` → `/var/solr` |
| JVM heap | **2 GB** (`SOLR_HEAP=2g`) |
| Restart policy | `unless-stopped` (survives reboots) |

### Solr Cores

| Core | Unique Key | Purpose |
|------|-----------|---------|
| `job` | `url` | Job listings with full-text search |
| `company` | `id` (CIF) | Company registry with status tracking |

### Authentication

| User | Password | Role |
|------|----------|------|
| `solr` | `SolrRocks` | `admin` |
| `reader` | `ReadOnly123` | `job-reader` (optional, add after install) |
| `writer` | `WriterPass` | `job-writer` (optional, add after install) |
| `deleter` | `DeleterPass` | `job-deleter` (optional, add after install) |

- **Mechanism**: Basic Auth via `security.json` (Solr `BasicAuthPlugin`)

### Authorization (Roles)

| Role | Can Read | Can Update/Delete | Security |
|------|----------|-------------------|----------|
| `admin` | ✅ All cores | ✅ Full access | ✅ Full |
| `job-reader` | ✅ All cores | ❌ Blocked (403) | ❌ |
| `job-writer` | ❌ Blocked (403) | ✅ Both insert & delete | ❌ |
| `job-deleter` | ❌ Blocked (403) | ✅ Both insert & delete | ❌ |

**Note**: Solr uses a single `/update` handler for both indexing and deleting documents. The `update` permission covers both operations — insert and delete cannot be separated at the Solr auth level. The `job-writer` and `job-deleter` roles have identical `update` permissions but exist as separate named roles for accountability/audit tracking.

### Auto-Update (Cron)

- **Time**: Daily at **3:00 AM**
- **Mechanism**: Compares Docker image digest before/after `docker pull solr:latest`
- **Zero download** if no update available (Docker caches manifests)
- **Swap**: Only stops/restarts container when digest changes
- **Logs**: `~/peviitor/solr-upgrade.log`

## Data Model

### Job Core Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `url` | string | Yes | Unique key, full URL to job detail |
| `title` | text_general | No | Position title, diacritics accepted |
| `company` | string | No | Legal company name |
| `cif` | string | No | CIF/CUI |
| `location` | text_general | No | Multi-valued, Romanian cities |
| `tags` | text_general | No | Multi-valued, lowercase, no diacritics |
| `workmode` | string | No | remote/on-site/hybrid |
| `status` | string | No | scraped→tested→verified→published |
| `salary` | text_general | No | Format: "MIN-MAX CURRENCY" |
| `date` | pdate | No | ISO8601 scrape timestamp |
| `vdate` | pdate | No | ISO8601 verified date |
| `expirationdate` | pdate | No | ISO8601 expiry date |

### Company Core Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | Yes | Unique key, CIF/CUI (8 digits) |
| `company` | string | No | Legal name, diacritics required, uppercase |
| `brand` | string | No | Commercial brand name |
| `group` | string | No | Parent company group |
| `status` | string | No | activ/suspendat/inactiv/radiat |
| `location` | text_general | No | Multi-valued, Romanian cities |
| `website` | string | No | Multi-valued, valid HTTP(S) URLs |
| `career` | string | No | Multi-valued, career page URLs |
| `lastScraped` | string | No | ISO8601 date of last scrape |
| `scraperFile` | string | No | Scraper filename reference |

## Verification

After installation, verify Solr is running:

```bash
# Check container
docker ps | grep peviitor-solr

# API ping (job core)
curl -u solr:SolrRocks http://localhost:8983/solr/job/admin/ping

# API ping (company core)
curl -u solr:SolrRocks http://localhost:8983/solr/company/admin/ping

# Web UI (from another machine)
# http://<raspberry-pi-ip>:8983/solr/

# Check auto-update log
cat ~/peviitor/solr-upgrade.log
```

## Maintenance

### Manual Upgrade

```bash
./002_upgrade_solr.sh
```

### Recreate a Core

```bash
# Job core
./003_recreate-job-core.sh
./004_url_uniquekey_pi.sh
./005_schema_jobs_pi.sh

# Company core
./006_recreate_company_core_pi.sh
./007_schema_company_pi.sh
```

### View Logs

```bash
docker logs peviitor-solr
```

### Stop / Start

```bash
docker stop peviitor-solr
docker start peviitor-solr
```

## Data Loading

Company data CSV chunks are in `data_sources/` at the repo root. Upload using:

```bash
../upload_to_solr.sh data_sources/chunk_aaa.csv http://localhost:8983/solr/company solr SolrRocks
```
