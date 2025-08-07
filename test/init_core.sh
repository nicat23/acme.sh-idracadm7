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
