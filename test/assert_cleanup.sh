#!/bin/sh
# test/assert_cleanup.sh — Validate broken symlink cleanup

. "$(dirname "$0")/env.sh"

echo "🔍 Asserting cleanup of broken symlinks..."

broken="$LE_BASE/deploy/broken.sh"

if [ -L "$broken" ]; then
  echo "❌ Broken symlink still exists: $broken"
  exit 1
else
  echo "✅ Broken symlink successfully removed"
fi
