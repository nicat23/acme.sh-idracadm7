============================================================
📄 File: test/bootstrap.sh
------------------------------------------------------------
#!/usr/bin/env sh

DEFAULT_BASE="/tmp/test/defaults/acme.sh"
TARGET_BASE="/tmp/test/acme"

mkdir -p "$DEFAULT_BASE/deploy" "$DEFAULT_BASE/dnsapi" "$DEFAULT_BASE/notify"

# Create dummy default files
for dir in deploy dnsapi notify; do
  for file in example.sh helper.sh; do
    path="$DEFAULT_BASE/$dir/$file"
    echo "#!/usr/bin/env sh\n# Default $file in $dir" > "$path"
    chmod +x "$path"
  done
done

# Simulate user bind mount: real file that should not be overwritten
mkdir -p "$TARGET_BASE/deploy"
echo "#!/usr/bin/env sh\n# USER OVERRIDE: do not replace" > "$TARGET_BASE/deploy/example.sh"
chmod +x "$TARGET_BASE/deploy/example.sh"

# Simulate broken symlink
ln -s /nonexistent/path "$TARGET_BASE/deploy/broken.sh"

# Simulate bad permissions: file exists but not executable
echo "#!/usr/bin/env sh\n# Not executable" > "$TARGET_BASE/deploy/unexecutable.sh"
chmod -x "$TARGET_BASE/deploy/unexecutable.sh"

echo "✅ Dummy defaults created under /tmp/test/defaults"
echo "⚠️  Simulated user bind mount: /tmp/test/acme/deploy/example.sh"
echo "⚠️  Simulated broken symlink: /tmp/test/acme/deploy/broken.sh → /nonexistent/path"
echo "⚠️  Simulated bad permissions: /tmp/test/acme/deploy/unexecutable.sh"

============================================================
📄 File: test/clean.sh
------------------------------------------------------------
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

============================================================
📄 File: test/clean_local.sh
------------------------------------------------------------
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

============================================================
📄 File: test/compare.sh
------------------------------------------------------------
#!/bin/sh

# Temp files
only_defaults="$(mktemp)"
only_acme="$(mktemp)"
diff_files="$(mktemp)"

# Flags
quiet=0
show_diff=0

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --quiet) quiet=1 ;;
        --diff) show_diff=1 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) break ;;
    esac
    shift
done

# Positional args
defaults="${1:-/defaults}"
acme="${2:-/acme}"

print_comparison_tree() {
    defaults_dir="$1"
    acme_dir="$2"
    rel_path="$3"
    prefix="$4"

    full_defaults="$defaults_dir/$rel_path"
    full_acme="$acme_dir/$rel_path"

    tmpfile="$(mktemp)"
    [ -d "$full_defaults" ] && ls -1 "$full_defaults" >> "$tmpfile"
    [ -d "$full_acme" ] && ls -1 "$full_acme" >> "$tmpfile"

    sort -u "$tmpfile" > "$tmpfile.sorted"

    while IFS= read -r entry; do
        sub_rel="$rel_path/$entry"
        path_defaults="$defaults_dir/$sub_rel"
        path_acme="$acme_dir/$sub_rel"

        marker=""
        if [ -L "$path_defaults" ] || [ -L "$path_acme" ]; then
            marker="🔗"
        elif [ -e "$path_defaults" ] && [ -e "$path_acme" ]; then
            if [ -f "$path_defaults" ] && [ -f "$path_acme" ]; then
                if cmp -s "$path_defaults" "$path_acme"; then
                    marker="✅"
                else
                    marker="❗"
                    echo "$sub_rel" >> "$diff_files"
                fi
            else
                marker="✅"
            fi
        elif [ -e "$path_defaults" ]; then
            marker="➕"
            echo "$sub_rel" >> "$only_defaults"
        elif [ -e "$path_acme" ]; then
            marker="⚠️"
            echo "$sub_rel" >> "$only_acme"
        fi

        # Show symlink target if applicable
        if [ "$marker" = "🔗" ]; then
            target=""
            [ -L "$path_defaults" ] && target="$(readlink "$path_defaults")"
            [ -z "$target" ] && [ -L "$path_acme" ] && target="$(readlink "$path_acme")"
            [ "$quiet" -eq 0 ] && echo "${prefix}├── $entry $marker → $target"
        else
            [ "$quiet" -eq 0 ] && echo "${prefix}├── $entry $marker"
        fi

        # Recurse into directories
        if [ -d "$path_defaults" ] || [ -d "$path_acme" ]; then
            print_comparison_tree "$defaults_dir" "$acme_dir" "$sub_rel" "${prefix}│   "
        fi
    done < "$tmpfile.sorted"

    rm -f "$tmpfile" "$tmpfile.sorted"
}

# Header
[ "$quiet" -eq 0 ] && {
    echo "Comparing:"
    echo "  Golden tree: $defaults"
    echo "  Mounted tree: $acme"
    echo ""
    echo "$(basename "$defaults") vs $(basename "$acme")"
}

print_comparison_tree "$defaults" "$acme" "" ""

# Summary
echo ""
echo "📋 Summary Report"
echo "-----------------"

count_only_defaults=$(wc -l < "$only_defaults")
count_only_acme=$(wc -l < "$only_acme")
count_diff_files=$(wc -l < "$diff_files")

[ "$count_only_defaults" -gt 0 ] && {
    echo "➕ Only in $defaults ($count_only_defaults):"
    sort "$only_defaults"
    echo ""
}

[ "$count_only_acme" -gt 0 ] && {
    echo "⚠️ Only in $acme ($count_only_acme):"
    sort "$only_acme"
    echo ""
}

[ "$count_diff_files" -gt 0 ] && {
    echo "❗ Differing files ($count_diff_files):"
    sort "$diff_files"
    echo ""
}

# Show diffs
if [ "$show_diff" -eq 1 ] && [ "$count_diff_files" -gt 0 ]; then
    echo "🔍 Unified Diffs"
    echo "----------------"
    while IFS= read -r rel; do
        echo "Diff: $rel"
        diff -u "$defaults/$rel" "$acme/$rel" || true
        echo ""
    done < "$diff_files"
fi

# Cleanup
rm -f "$only_defaults" "$only_acme" "$diff_files"

============================================================
📄 File: test/diff.sh
------------------------------------------------------------
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

============================================================
📄 File: test/env.local.sh
------------------------------------------------------------
#!/bin/sh
# test/env.local.sh — Local overrides for dry-run testing

# Enable debug output in scripts
export DBG=true

# Override base path for dry-run tree
export LE_BASE="/tmp/justin/acme"

# Optional: override other dry-run paths
export LE_WORKING_DIR="/tmp/test/defaults"
export LE_CONFIG_HOME="/tmp/test/config"
export LE_CERT_HOME="/tmp/test/certs"

# Enable preview mode for cleanup scripts
export PREVIEW=false

============================================================
📄 File: test/env.sh
------------------------------------------------------------
#!/bin/sh
# test/env.sh

echo "✅ Sourcing test/env.sh"

export DRYRUN=true
export DBG=true
export TEST_MODE=true  # Enable test compatibility mode

export LE_BASE="/tmp/test/acme"
export LE_WORKING_DIR="/tmp/test/defaults"
export LE_CONFIG_HOME="/tmp/test/config"
export LE_CERT_HOME="/tmp/test/certs"

# Optional local overrides
if [ -f "$(dirname "$0")/env.local.sh" ]; then
  echo "🔧 Sourcing local overrides from env.local.sh"
  . "$(dirname "$0")/env.local.sh"
fi
============================================================
📄 File: test/init_core.sh
------------------------------------------------------------
#!/bin/sh
# test/init_core.sh

echo "🧪 Simulating core initialization..."

# Example: check if config dir exists
if [ ! -d "$LE_CONFIG_HOME" ]; then
  echo "❌ Config directory missing: $LE_CONFIG_HOME"
  exit 1
fi

# Simulate a config file
touch "$LE_CONFIG_HOME/dummy.conf"
echo "✅ Core initialization complete."

============================================================
📄 File: test/init_core_dryrun.sh
------------------------------------------------------------
#!/usr/bin/env sh
. "$(dirname "$0")/../init/env.sh"
. "$(dirname "$0")/../init/init_core.sh"

initialize_acme_core

============================================================
📄 File: test/init_dirs.sh
------------------------------------------------------------
#!/bin/sh
# test/init_dirs.sh

echo "📁 Initializing dry-run directories..."

mkdir -p "$LE_BASE"
mkdir -p "$LE_WORKING_DIR"
mkdir -p "$LE_CONFIG_HOME"
mkdir -p "$LE_CERT_HOME"

echo "✅ Dry-run directories ready:"
echo "  - LE_BASE=$LE_BASE"
echo "  - LE_WORKING_DIR=$LE_WORKING_DIR"
echo "  - LE_CONFIG_HOME=$LE_CONFIG_HOME"
echo "  - LE_CERT_HOME=$LE_CERT_HOME"

============================================================
📄 File: test/init_dirs_dryrun.sh
------------------------------------------------------------
#!/usr/bin/env sh
. "$(dirname "$0")/../init/env.sh"
. "$(dirname "$0")/../init/init_dirs.sh"

initialize_directory "acme.sh/deploy" "deploy"
initialize_directory "acme.sh/dnsapi" "dnsapi"
initialize_directory "acme.sh/notify" "notify"

============================================================
📄 File: test/init_dryrun.sh
------------------------------------------------------------
#!/bin/sh
# test/init_dryrun.sh

. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/init_dirs.sh"
. "$(dirname "$0")/init_core.sh"
. "$(dirname "$0")/setup.sh"
. "$(dirname "$0")/../init/main.sh"

main

============================================================
📄 File: test/report.sh
------------------------------------------------------------
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

============================================================
📄 File: test/setup.sh
------------------------------------------------------------
#!/bin/sh
# test/setup.sh

echo "🔧 Simulating setup artifacts..."

DEPLOY_DIR="$LE_BASE/deploy"
mkdir -p "$DEPLOY_DIR"

# Simulate user bind mount
touch "$DEPLOY_DIR/example.sh"
echo "⚠️  Simulated user bind mount: $DEPLOY_DIR/example.sh"

# Simulate broken symlink
ln -sf /nonexistent/path "$DEPLOY_DIR/broken.sh"
echo "⚠️  Simulated broken symlink: $DEPLOY_DIR/broken.sh → /nonexistent/path"

# Simulate bad permissions
touch "$DEPLOY_DIR/unexecutable.sh"
chmod -x "$DEPLOY_DIR/unexecutable.sh"
echo "⚠️  Simulated bad permissions: $DEPLOY_DIR/unexecutable.sh"

============================================================
📄 File: test/setup_dryrun.sh
------------------------------------------------------------
#!/usr/bin/env sh
. "$(dirname "$0")/../init/env.sh"
. "$(dirname "$0")/../init/setup.sh"

setup_acme_symlink
setup_cron_job

============================================================
📄 File: test/validate.sh
------------------------------------------------------------
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

============================================================
📄 File: test/watch.sh
------------------------------------------------------------
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

