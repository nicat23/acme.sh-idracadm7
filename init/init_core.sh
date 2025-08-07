#!/usr/bin/env sh
. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/logging.sh"
. "$(dirname "$0")/symlinks.sh"

initialize_acme_core() {
  local default_dir="$LE_WORKING_DIR/acme.sh"
  local target_dir="$LE_BASE"

  echo "Initializing acme.sh core files..." >&1
  dryrun_log "Would create directory: $target_dir"
  [ "$DRYRUN" = "true" ] || mkdir -p "$target_dir" || {
    echo "Warning: Failed to create $target_dir" >&1
    return 1
  }

  find "$default_dir" -maxdepth 1 -type f | while IFS= read -r default_file; do
    filename=$(basename "$default_file")
    target_file="$target_dir/$filename"
    symlink_file_with_structure "$default_file" "$target_file" "$filename"
  done
}
