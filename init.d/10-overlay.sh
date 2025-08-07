#!/usr/bin/env bash
set -eu
source /init.d/00-env.sh

compare_checksums() {
  local f1="$1" f2="$2"
  local sum1 sum2
  sum1="$(sha256sum "$f1" | awk '{print $1}')"
  sum2="$(sha256sum "$f2" | awk '{print $1}')"
  [[ "$sum1" != "$sum2" ]]
}

overlay_dir() {
  local name="$1"
  local dst="$TARGET_DIR/$name"
  local user_src="$HOST_DIR/$name"
  local default_src="$DEFAULTS_DIR/$name"

  log "🔍 Overlaying $name scripts into $dst..."
  mkdir -p "$dst" "$dst/.origin"

  for src in "$user_src" "$default_src"; do
    [[ -d "$src" ]] || continue
    for f in "$src"/*.sh; do
      base="$(basename "$f")"
      target="$dst/$base"
      origin="$src"

      if [[ -e "$target" ]]; then
        # Detect shadowed defaults
        if [[ "$src" == "$DEFAULTS_DIR/$name" && -e "$user_src/$base" ]]; then
          if compare_checksums "$f" "$user_src/$base"; then
            log "⚠️ Shadowed default: $base differs from user-supplied version"
          fi
        fi
        debug "⚠️ Skipping existing $base in $dst"
        continue
      fi

      if [[ "$DRY_RUN" == "true" ]]; then
        log "[dry-run] Would copy $base from $src → $dst"
      else
        cp "$f" "$target"
        echo "$origin" > "$dst/.origin/$base"
        log "📁 Copied $base from $src → $dst"
      fi
    done
  done
}

overlay_dir "deploy"
overlay_dir "dnsapi"
overlay_dir "notify"
