#!/bin/sh
# test/simulate_missing_notify.sh — Remove /defaults/notify to test fallback

. "$(dirname "$0")/env.sh"

notify_dir="$LE_WORKING_DIR/notify"

if [ -d "$notify_dir" ]; then
  rm -rf "$notify_dir"
  echo "⚠️ Removed $notify_dir to simulate missing source directory"
else
  echo "ℹ️ $notify_dir already missing — no action needed"
fi
