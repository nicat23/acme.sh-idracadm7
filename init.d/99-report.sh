#!/usr/bin/env bash

echo "[init] Initialization complete."

echo "[init] DRY_RUN=${DRY_RUN}, DEBUG=${DEBUG}, SYNC_MODE=${SYNC_MODE:-symlink}"

echo "[init] Target folders populated in /acme/*:"
for dir in deploy dnsapi notify; do
  count=$(find "/acme/${dir}" -type f -name '*.sh' | wc -l)
  echo "  - /acme/${dir}: ${count} script(s)"
done

echo "[init] Config directory: ${LE_CONFIG_HOME}"
echo "[init] Certs directory:  ${LE_CERT_HOME}"
echo "[init] acme.sh home:     ${LE_BASE}"

if [ "${DEBUG}" = "true" ]; then
  echo "[init] 🔍 Listing /acme contents:"
  find /acme -type f | sort
fi
