#!/bin/sh
set -e

echo "Initializing ACME appliance..."

if [ -x /init/overlay.sh ]; then
    /init/overlay.sh
fi

exec /acmebin/acme.sh "$@"