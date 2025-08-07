#!/bin/sh
# test/watch.sh

. "$(dirname "$0")/env.sh"

echo "👀 Watching dry-run environment at $LE_BASE..."

if command -v inotifywait >/dev/null 2>&1; then
  echo "🔄 Using inotifywait for live updates..."
  inotifywait -m -r "$LE_BASE" "$LE_WORKING_DIR" "$LE_CONFIG_HOME" "$LE_CERT_HOME" \
    --format '%T %w%f %e' --timefmt '%H:%M:%S' \
    -e create -e modify -e delete -e move
else
  echo "⚠️  inotifywait not found — falling back to watch + tree"
  watch -n 2 "tree -pug $LE_BASE"
fi
