#!/usr/bin/env sh
. "$(dirname "$0")/../init/env.sh"
. "$(dirname "$0")/../init/setup.sh"

setup_acme_symlink
setup_cron_job
