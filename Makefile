# Paths for testing
LE_BASE := /tmp/test/acme
LE_WORKING_DIR := /tmp/test/defaults
LE_CONFIG_HOME := /tmp/test/config
LE_CERT_HOME := /tmp/test/certs

# Common flags
ENV_VARS := DRYRUN=true DBG=true \
    LE_BASE=$(LE_BASE) \
    LE_WORKING_DIR=$(LE_WORKING_DIR) \
    LE_CONFIG_HOME=$(LE_CONFIG_HOME) \
    LE_CERT_HOME=$(LE_CERT_HOME)

# Entrypoint
all: dryrun-main

dryrun-main:
    @echo "🔧 Running full dry-run initialization..."
    @env $(ENV_VARS) sh test/init_dryrun.sh

dryrun-core:
    @echo "🔧 Testing acme.sh core symlinks..."
    @env $(ENV_VARS) sh test/init_core_dryrun.sh

dryrun-dirs:
    @echo "🔧 Testing directory initialization..."
    @env $(ENV_VARS) sh test/init_dirs_dryrun.sh

dryrun-setup:
    @echo "🔧 Testing setup logic (symlink + cron)..."
    @env $(ENV_VARS) sh test/setup_dryrun.sh

clean:
    @echo "🧹 Cleaning test directories..."
    @rm -rf /tmp/test
