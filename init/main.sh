#!/usr/bin/env sh
# Enhanced main.sh - Container initialization orchestrator

set -e  # Exit on error

# Source environment and utilities
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/env.sh"
. "$SCRIPT_DIR/logging.sh"
. "$SCRIPT_DIR/init_core.sh"
. "$SCRIPT_DIR/init_dirs.sh"
. "$SCRIPT_DIR/setup.sh"

main() {
  echo "🚀 Starting acme.sh container initialization..."
  echo "📋 Environment:"
  echo "  - LE_BASE: $LE_BASE"
  echo "  - LE_WORKING_DIR: $LE_WORKING_DIR" 
  echo "  - LE_CONFIG_HOME: $LE_CONFIG_HOME"
  echo "  - LE_CERT_HOME: $LE_CERT_HOME"
  echo "  - DRYRUN: ${DRYRUN:-false}"
  echo "  - DBG: ${DBG:-false}"
  echo ""

  # Step 1: Initialize core acme.sh files
  echo "🔧 Step 1: Initializing acme.sh core..."
  initialize_acme_core || {
    echo "❌ Failed to initialize acme.sh core" >&2
    exit 1
  }
  echo ""

  # Step 2: Initialize directory structure (deploy, dnsapi, notify)
  echo "🔧 Step 2: Initializing acme.sh directories..."
  for subdir in deploy dnsapi notify; do
    echo "📁 Processing $subdir directory..."
    initialize_directory "acme.sh/$subdir" "$subdir" || {
      echo "⚠️ Warning: Failed to initialize $subdir directory" >&2
    }
  done
  echo ""

  # Step 3: Setup symlinks and cron
  echo "🔧 Step 3: Setting up acme.sh integration..."
  setup_acme_symlink || {
    echo "⚠️ Warning: Failed to setup acme.sh symlink" >&2
  }
  
  setup_cron_job || {
    echo "⚠️ Warning: Failed to setup cron job" >&2
  }
  echo ""

  # Step 4: Verify installation
  echo "🔧 Step 4: Verifying installation..."
  verify_installation
  echo ""

  echo "✅ Container initialization complete!"
  echo ""
}

verify_installation() {
  local errors=0
  
  # Check if acme.sh is accessible
  if [ -f "$LE_BASE/acme.sh" ] && [ -x "$LE_BASE/acme.sh" ]; then
    echo "✅ acme.sh core file is present and executable"
  else
    echo "❌ acme.sh core file missing or not executable" >&2
    errors=$((errors + 1))
  fi

  # Check if symlink exists
  if [ -L /usr/local/bin/acme.sh ] && [ -e /usr/local/bin/acme.sh ]; then
    echo "✅ acme.sh symlink is valid"
  else
    echo "❌ acme.sh symlink missing or broken" >&2
    errors=$((errors + 1))
  fi

  # Check directory structure
  for dir in deploy dnsapi notify; do
    if [ -d "$LE_BASE/$dir" ]; then
      local count=$(find "$LE_BASE/$dir" -name "*.sh" | wc -l)
      echo "✅ $dir directory ready ($count scripts)"
    else
      echo "❌ $dir directory missing" >&2
      errors=$((errors + 1))
    fi
  done

  # Check cron job
  if crontab -l 2>/dev/null | grep -q acme.sh; then
    echo "✅ Cron job configured"
  else
    echo "⚠️ Cron job not found (may be intentional)" >&2
  fi

  # Report any broken symlinks
  local broken_links
  broken_links=$(find "$LE_BASE" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
  if [ "$broken_links" -gt 0 ]; then
    echo "⚠️ Found $broken_links broken symlink(s)" >&2
    find "$LE_BASE" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r link; do
      echo "  - $link"
    done
  else
    echo "✅ No broken symlinks found"
  fi

  if [ "$errors" -gt 0 ]; then
    echo "⚠️ Initialization completed with $errors error(s)" >&2
    return 1
  fi
}

# Execute main function
main "$@"