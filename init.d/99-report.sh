#!/usr/bin/env bash
set -euo pipefail
source /init.d/00-env.sh

log "Initialization complete."
log "DRY_RUN=$DRY_RUN, DEBUG=$DEBUG, SYNC_MODE=$SYNC_MODE"
log "Target folders populated in /acme/*"
