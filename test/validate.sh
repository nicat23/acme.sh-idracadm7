#!/bin/sh
# test/validate.sh

. "$(dirname "$0")/env.sh"

echo "🔍 Validating dry-run environment..."

errors=0

# Check for broken symlinks
echo "🔗 Checking for broken symlinks..."
find "$LE_BASE" -type l ! -exec test -e {} \; -print | while read -r link; do
  echo "❌ Broken symlink: $link"
  errors=$((errors + 1))
done

# Check for unexecutable .sh files
echo "🔐 Checking for unexecutable .sh files..."
find "$LE_BASE" -type f -name "*.sh" ! -perm -u+x | while read -r file; do
  echo "❌ Not executable: $file"
  errors=$((errors + 1))
done

# Check for missing config file
echo "📄 Checking for dummy config..."
if [ ! -f "$LE_CONFIG_HOME/dummy.conf" ]; then
  echo "❌ Missing config: $LE_CONFIG_HOME/dummy.conf"
  errors=$((errors + 1))
fi

# Check for empty directories
echo "📁 Checking for empty directories..."
for dir in "$LE_BASE" "$LE_WORKING_DIR" "$LE_CONFIG_HOME" "$LE_CERT_HOME"; do
  find "$dir" -type d -empty | while read -r empty; do
    echo "⚠️  Empty directory: $empty"
  done
done

# Summary
if [ "$errors" -gt 0 ]; then
  echo "❌ Validation failed with $errors error(s)."
  exit 1
else
  echo "✅ Validation passed."
fi
