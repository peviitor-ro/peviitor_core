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

run_step "000_tools.sh"                    bash 000_tools.sh
run_step "001_apache_solr.sh"              bash 001_apache_solr.sh
run_step "002_upgrade_solr.sh"             bash 002_upgrade_solr.sh
run_step "003_recreate-job-core.sh"        bash 003_recreate-job-core.sh
run_step "004_url_uniquekey_pi.sh"         bash 004_url_uniquekey_pi.sh
run_step "005_schema_jobs_pi.sh"           bash 005_schema_jobs_pi.sh
run_step "006_recreate_company_core_pi.sh" bash 006_recreate_company_core_pi.sh
run_step "007_schema_company_pi.sh"        bash 007_schema_company_pi.sh
run_step "008_enable_solr_basic_auth_pi.sh" bash 008_enable_solr_basic_auth_pi.sh
run_step "009_auto_update_solr.sh"         bash 009_auto_update_solr.sh
run_step "010_setup_cron.sh"               bash 010_setup_cron.sh

echo "=== RULARE install.sh TERMINATA (verifica mesajele de mai sus pentru erori). ==="
