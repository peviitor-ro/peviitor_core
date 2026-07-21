#!/usr/bin/env bash
set -e

CONTAINER="peviitor-solr"
IMAGE="solr:latest"
LOG_FILE="$HOME/peviitor/solr-upgrade.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== Checking for Solr Docker image update ==="

# Get current image digest from running container
CURRENT_DIGEST=$(docker inspect "$CONTAINER" --format '{{.Image}}' 2>/dev/null || echo "none")
log "Current container image: $CURRENT_DIGEST"

# Pull latest (no-op if digest unchanged — zero download)
docker pull "$IMAGE" > /dev/null 2>&1

# Get new image digest
NEW_DIGEST=$(docker image inspect "$IMAGE" --format '{{.Id}}')
log "Latest image digest:    $NEW_DIGEST"

if [ "$CURRENT_DIGEST" = "$NEW_DIGEST" ]; then
  log "No update needed. Exiting."
  exit 0
fi

log "=== New Solr version detected! Upgrading... ==="

# Stop and remove old container
docker stop "$CONTAINER" || true
docker rm "$CONTAINER" || true

# Start new container with same config
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p 8983:8983 \
  -v "$HOME/peviitor/solr:/var/solr" \
  -e SOLR_HEAP=2g \
  "$IMAGE"

log "=== Upgrade complete: $CURRENT_DIGEST -> $NEW_DIGEST ==="
log "Container $CONTAINER restarted with solr:latest."

# Wait and verify
sleep 15
if docker ps | grep -q "$CONTAINER"; then
  log "Container is running. Verification OK."
else
  log "WARNING: Container failed to start. Check logs: docker logs $CONTAINER"
fi
