#!/bin/sh
# test/clean.sh — Remove dry-run test directory

TARGET="/tmp/test"

echo "🧹 Cleaning dry-run path: $TARGET"

if [ -d "$TARGET" ]; then
  if [ "$PREVIEW" = "true" ]; then
    echo "🔍 Preview: would remove $TARGET"
  else
    rm -rf "$TARGET"
    echo "✅ Removed $TARGET"
  fi
else
  echo "ℹ️  No dry-run path found — nothing to clean."
fi
