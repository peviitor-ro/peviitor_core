#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/009_auto_update_solr.sh"
CRON_SCHEDULE="0 3 * * *"
CRON_LABEL="peviitor-solr-auto-update"

echo "=== Setting up daily cron for Solr auto-update ==="
echo "Script: $UPDATE_SCRIPT"
echo "Schedule: $CRON_SCHEDULE (daily at 3:00 AM)"
echo ""

# Make sure the script is executable
chmod +x "$UPDATE_SCRIPT"

# Remove any previous entry with the same label
crontab -l 2>/dev/null \
  | grep -v "$CRON_LABEL" \
  > /tmp/crontab_cleaned 2>/dev/null || true

# Add the new entry
echo "$CRON_SCHEDULE $UPDATE_SCRIPT >> \$HOME/peviitor/solr-upgrade.log 2>&1 # $CRON_LABEL" \
  >> /tmp/crontab_cleaned

crontab /tmp/crontab_cleaned
rm -f /tmp/crontab_cleaned

echo "=== Current crontab ==="
crontab -l 2>/dev/null || echo "(empty)"
echo ""
echo "=== DONE: Cron installed. Daily check at 3:00 AM ==="
echo "Logs: ~/peviitor/solr-upgrade.log"
