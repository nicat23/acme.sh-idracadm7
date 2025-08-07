#!/usr/bin/env sh
. "$(dirname "$0")/logging.sh"

symlink_file_with_structure() {
  local src_file=$1
  local dest_file=$2
  local relative_path=$3

  dest_dir=$(dirname "$dest_file")
  if [ ! -d "$dest_dir" ]; then
    dryrun_log "Would create directory: $dest_dir"
    [ "$DRYRUN" = "true" ] || mkdir -p "$dest_dir" || {
      echo "Warning: Failed to create directory $dest_dir" >&1
      return 1
    }
  fi

  # Handle existing file or symlink
  if [ -e "$dest_file" ]; then
    if [ -L "$dest_file" ]; then
      # Check for broken symlink
      if [ ! -e "$(readlink "$dest_file")" ]; then
        echo "Warning: $relative_path is a broken symlink, replacing" >&1
        dryrun_log "Would replace broken symlink: $dest_file"
        [ "$DRYRUN" = "true" ] || rm -f "$dest_file"
      else
        log "Valid symlink exists for $relative_path, skipping"
        return 0
      fi
    else
      echo "Warning: $relative_path exists and is not a symlink, skipping" >&1
      return 1
    fi
  fi

  dryrun_log "Would symlink: $src_file → $dest_file"
  [ "$DRYRUN" = "true" ] || ln -sf "$src_file" "$dest_file" || {
    echo "Warning: Failed to symlink $relative_path" >&1
    return 1
  }

  # Ensure .sh files are executable
  if echo "$relative_path" | grep -q '\.sh$'; then
    if [ ! -x "$src_file" ]; then
      echo "Warning: $src_file is not executable, fixing" >&1
      dryrun_log "Would chmod +x on: $src_file"
      [ "$DRYRUN" = "true" ] || chmod +x "$src_file" || {
        echo "Warning: Failed to set execute permission on $src_file" >&1
      }
    else
      log "Executable verified: $src_file"
    fi
  fi

  log "Symlinked: $relative_path"
  return 0
}

sync_directory_files() {
  local default_dir=$1
  local target_dir=$2
  local dir_name=$3

  [ -d "$default_dir" ] || {
    echo "Warning: Default directory $default_dir not found" >&1
    return 1
  }

  log "Syncing $dir_name directory files..."
  [ "$DRYRUN" = "true" ] || mkdir -p "$target_dir" || {
    echo "Warning: Failed to create $target_dir" >&1
    return 1
  }

  local created=0
  local skipped=0
  local replaced=0
  local fixed_exec=0

  find "$default_dir" -type f | while IFS= read -r default_file; do
    relative_path=${default_file#$default_dir}
    relative_path=${relative_path#/}
    target_file="$target_dir/$relative_path"

    # Capture output from symlink logic
    output=$(symlink_file_with_structure "$default_file" "$target_file" "$relative_path" 2>&1)

    echo "$output" | grep -q "Symlinked:" && created=$((created + 1))
    echo "$output" | grep -q "skipping" && skipped=$((skipped + 1))
    echo "$output" | grep -q "replacing" && replaced=$((replaced + 1))
    echo "$output" | grep -q "fixing" && fixed_exec=$((fixed_exec + 1))
  done

  echo "📦 $dir_name summary:"
  echo "  ✅ Symlinks created: $created"
  echo "  ⚠️  Skipped (existing files): $skipped"
  echo "  🔁 Replaced broken symlinks: $replaced"
  echo "  🛠️  Fixed permissions: $fixed_exec"
}

