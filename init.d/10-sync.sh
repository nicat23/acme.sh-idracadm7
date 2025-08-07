#!/usr/bin/env bash
set -euo pipefail

source /init.d/00-env.sh

sync_dir() {
  local name="$1"
  local src="$DEFAULTS_DIR/$name"
  local dst="$TARGET_DIR/$name"

  if [[ ! -d "$src" ]]; then
    log "⚠️ Skipping $name: source directory $src not found"
    return
  fi

  mkdir -p "$dst"
  debug "Syncing $name: src=$src, dst=$dst"

  # Cleanup broken symlinks
  find "$dst" -type l ! -exec test -e {} \; -print -delete | while read -r broken; do
    log "🧹 Removed broken symlink: $broken"
  done

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
        log "🔗 Symlinked: $file → $target"
      elif [[ "$SYNC_MODE" == "copy" ]]; then
        cp "$file" "$target"
        log "📄 Copied: $file → $target"
      else
        log "❌ Unknown SYNC_MODE: $SYNC_MODE"
        exit 1
      fi
    fi
  done
}

for dir in deploy dnsapi notify; do
  sync_dir "$dir"
done
