#!/bin/sh
# test/env.sh

echo "✅ Sourcing test/env.sh"

export DRYRUN=true
export DBG=true

export LE_BASE="/tmp/test/acme"
export LE_WORKING_DIR="/tmp/test/defaults"
export LE_CONFIG_HOME="/tmp/test/config"
export LE_CERT_HOME="/tmp/test/certs"

# Optional local overrides
if [ -f "$(dirname "$0")/env.local.sh" ]; then
  echo "🔧 Sourcing local overrides from env.local.sh"
  . "$(dirname "$0")/env.local.sh"
fi
