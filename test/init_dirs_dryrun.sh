#!/usr/bin/env sh
. "$(dirname "$0")/../init/env.sh"
. "$(dirname "$0")/../init/init_dirs.sh"

initialize_directory "acme.sh/deploy" "deploy"
initialize_directory "acme.sh/dnsapi" "dnsapi"
initialize_directory "acme.sh/notify" "notify"
