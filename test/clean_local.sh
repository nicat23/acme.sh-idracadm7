#!/bin/sh
# test/clean_local.sh — Remove local override test directory

TARGET="${LE_BASE:-/tmp/test-local}"

echo "🧹 Cleaning local override path: $TARGET"

if [ -d "$TARGET" ]; then
  if [ "$PREVIEW" = "true" ]; then
    echo "🔍 Preview: would remove $TARGET"
  else
    rm -rf "$TARGET"
    echo "✅ Removed $TARGET"
  fi
else
  echo "ℹ️  No override path found — nothing to clean."
fi
