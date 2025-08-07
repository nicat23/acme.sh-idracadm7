#!/bin/sh
# test/diff.sh

. "$(dirname "$0")/env.sh"

echo "🔍 Comparing dry-run tree against golden reference..."

# Use diff to compare structure and symlink targets
diff_output=$(diff -qr "$LE_WORKING_DIR/acme.sh" "$LE_BASE" 2>/dev/null)

if [ -z "$diff_output" ]; then
  echo "✅ No differences found — dry-run tree matches golden reference."
else
  echo "❌ Differences detected:"
  echo "$diff_output"
  echo ""
  echo "🔍 Tip: Use diff -r for full recursive comparison."
  exit 1
fi
