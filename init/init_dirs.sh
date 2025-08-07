#!/usr/bin/env sh
. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/logging.sh"
. "$(dirname "$0")/paths.sh"
. "$(dirname "$0")/symlinks.sh"

initialize_directory() {
  local subpath=$1
  local label=$2
  read default_dir target_dir < <(resolve_paths "$subpath")

  echo "Initializing $label directory..." >&1
  dryrun_log "Would create directory: $target_dir"
  [ "$DRYRUN" = "true" ] || mkdir -p "$target_dir" || {
    echo "Warning: Failed to create $target_dir" >&1
    return 1
  }

  local user_files_count
  user_files_count=$(find "$target_dir" -type f ! -name ".*" 2>/dev/null | wc -l)

  if [ "$user_files_count" -eq 0 ]; then
    dryrun_log "Would copy all defaults from $default_dir to $target_dir"
    if [ "$DRYRUN" != "true" ]; then
      cp -r "$default_dir"/* "$target_dir"/ || {
        echo "Warning: Failed to copy default $label files" >&1
      }
      find "$target_dir" -name "*.sh" -exec chmod +x {} \; || {
        echo "Warning: Failed to set permissions on $label scripts" >&1
      }
    fi
  else
    dryrun_log "Would symlink missing defaults from $default_dir to $target_dir"
    sync_directory_files "$default_dir" "$target_dir" "$label"
  fi
}
