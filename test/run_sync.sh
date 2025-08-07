#!/bin/sh
# test/run_sync.sh — Execute sync logic with dry-run and mode support

. "$(dirname "$0")/env.sh"

echo "🚀 Running sync logic with SYNC_MODE=$SYNC_MODE, DRY_RUN=$DRY_RUN"

INIT_SCRIPT="$(dirname "$0")/../init.d/10-sync.sh"

if [ ! -f "$INIT_SCRIPT" ]; then
  echo "❌ Missing init script: $INIT_SCRIPT"
  exit 1
fi

sh "$INIT_SCRIPT"
