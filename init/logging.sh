#!/usr/bin/env sh
log() {
  if [ "${DBG}" = "true" ]; then
    echo "[DEBUG] $*" >&1
  fi
}
dryrun_log() {
  if [ "${DRYRUN}" = "true" ]; then
    echo "[DRYRUN] $*" >&1
  fi
}
