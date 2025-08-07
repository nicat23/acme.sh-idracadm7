#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
DEBUG="${DEBUG:-false}"
SYNC_MODE="${SYNC_MODE:-symlink}"  # unused now, but retained for future
DEFAULTS_DIR="/defaults"
HOST_DIR="/mnt"
TARGET_DIR="/acme"

log()   { echo "[init] $*"; }
debug() { [[ "$DEBUG" == "true" ]] && echo "[debug] $*" >&2; }
