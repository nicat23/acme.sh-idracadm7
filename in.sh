============================================================
📄 File: init.d/00-env.sh
------------------------------------------------------------
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
DEBUG="${DEBUG:-false}"
SYNC_MODE="${SYNC_MODE:-symlink}"  # or "copy"

DEFAULTS_DIR="/defaults"
HOST_DIR="/mnt"
TARGET_DIR="/acme"

log() { echo "[init] $*"; }
debug() { [[ "$DEBUG" == "true" ]] && echo "[debug] $*" >&2; }

============================================================
📄 File: init.d/10-sync.sh
------------------------------------------------------------
#!/usr/bin/env bash
set -euo pipefail

source /init.d/00-env.sh

sync_dir() {
  local name="$1"
  local src="$DEFAULTS_DIR/$name"
  local dst="$TARGET_DIR/$name"

  mkdir -p "$dst"
  debug "Syncing $name: src=$src, dst=$dst"

  for file in "$src"/*; do
    [[ -f "$file" ]] || continue
    local base="$(basename "$file")"
    local target="$dst/$base"

    if [[ -e "$target" ]]; then
      debug "Skipping existing: $target"
      continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      log "[dry-run] Would ${SYNC_MODE} $file → $target"
    else
      if [[ "$SYNC_MODE" == "symlink" ]]; then
        ln -s "$file" "$target"
        log "Symlinked: $file → $target"
      else
        cp "$file" "$target"
        log "Copied: $file → $target"
      fi
    fi
  done
}

for dir in deploy dnsapi notify; do
  sync_dir "$dir"
done

============================================================
📄 File: init.d/99-report.sh
------------------------------------------------------------
#!/usr/bin/env bash
set -euo pipefail
source /init.d/00-env.sh

log "Initialization complete."
log "DRY_RUN=$DRY_RUN, DEBUG=$DEBUG, SYNC_MODE=$SYNC_MODE"
log "Target folders populated in /acme/*"

