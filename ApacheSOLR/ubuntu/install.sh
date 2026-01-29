#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

run_step() {
  local name="$1"
  shift
  echo "=== $name ==="
  if "$@"; then
    echo "[$name] OK"
  else
    echo "[$name] A ESUAT (exit code $?), CONTINUAM..."
  fi
  echo
}

run_step "000_tools.sh"               bash 000_tools.sh
run_step "001_apache_solr.sh"         bash 001_apache_solr.sh
run_step "002_upgrade_solr.sh"        bash 002_upgrade_solr.sh
run_step "003_recreate-job-core.sh"   bash 003_recreate-job-core.sh
run_step "004_url_uniquekey.sh"       bash 004_url_uniquekey.sh
run_step "005_schema_jobs.sh"         bash 005_schema_jobs.sh
run_step "006_recreate_company_core.sh" bash 006_recreate_company_core.sh
run_step "007_schema_company.sh"      bash 007_schema_company.sh
run_step "008_enable_solr_basic_auth.sh" bash 008_enable_solr_basic_auth.sh

echo "=== RULARE go.sh TERMINATA (unele pasi pot sa fi esuat, vezi mesajele de mai sus). ==="