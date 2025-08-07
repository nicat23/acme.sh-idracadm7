#!/bin/sh
# test/report.sh

. "$(dirname "$0")/env.sh"

echo "📊 Dry-run environment report"

echo ""
echo "📁 Directory summary:"
find "$LE_BASE" "$LE_WORKING_DIR" "$LE_CONFIG_HOME" "$LE_CERT_HOME" -type d | wc -l | xargs echo "  - Total directories:"

echo ""
echo "📄 File summary:"
find "$LE_BASE" "$LE_WORKING_DIR" "$LE_CONFIG_HOME" "$LE_CERT_HOME" -type f | wc -l | xargs echo "  - Total files:"

echo ""
echo "🔗 Symlink summary:"
total_links=$(find "$LE_BASE" -type l | wc -l)
broken_links=$(find "$LE_BASE" -type l ! -exec test -e {} \; | wc -l)
echo "  - Total symlinks: $total_links"
echo "  - Broken symlinks: $broken_links"

echo ""
echo "🔐 Executable script summary:"
exec_count=$(find "$LE_BASE" -type f -name "*.sh" -perm -u+x | wc -l)
non_exec_count=$(find "$LE_BASE" -type f -name "*.sh" ! -perm -u+x | wc -l)
echo "  - Executable .sh files: $exec_count"
echo "  - Non-executable .sh files: $non_exec_count"

echo ""
echo "📦 Disk usage:"
du -sh /tmp/test /tmp/justin 2>/dev/null
