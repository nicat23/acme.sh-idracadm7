#!/usr/bin/env sh

symlink_file_with_structure() {
  local src_file=$1
  local dest_file=$2
  local relative_path=$3

  dest_dir=$(dirname "$dest_file")
  if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir" 2>&1 || {
      echo "Warning: Failed to create directory $dest_dir" >&1
      return 1
    }
  fi

  if [ -e "$dest_file" ] && [ ! -L "$dest_file" ]; then
    echo "Warning: $relative_path exists and is not a symlink, skipping" >&1
    return 1
  fi

  ln -sf "$src_file" "$dest_file" 2>&1 || {
    echo "Warning: Failed to symlink $relative_path" >&1
    return 1
  }

  if echo "$relative_path" | grep -q '\.sh$'; then
    chmod +x "$src_file" 2>&1 || {
      echo "Warning: Failed to set execute permission on $src_file" >&1
    }
  fi

  echo "  Symlinked: $relative_path" >&1
  return 0
}

sync_directory_files() {
  local default_dir=$1
  local target_dir=$2
  local dir_name=$3

  if [ ! -d "$default_dir" ]; then
    echo "Warning: Default directory $default_dir not found" >&1
    return 1
  fi

  echo "Syncing $dir_name directory files..." >&1

  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir" 2>&1 || {
      echo "Warning: Failed to create $target_dir" >&1
      return 1
    }
  fi

  find "$default_dir" -type f | while IFS= read -r default_file; do
    relative_path=${default_file#$default_dir}
    relative_path=${relative_path#/}
    target_file="$target_dir/$relative_path"

    if [ ! -f "$target_file" ] && [ ! -L "$target_file" ]; then
      symlink_file_with_structure "$default_file" "$target_file" "$relative_path"
    fi
  done

  return 0
}

initialize_acme_core() {
  local default_dir=${LE_WORKING_DIR:-"/defaults/acme"}
  local target_dir="${LE_BASE:-"/acme"}"

  if [ ! -d "$default_dir" ]; then
    echo "Warning: Default acme.sh directory not found" >&1
    return 1
  fi

  echo "Initializing acme.sh core files..." >&1

  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir" 2>&1 || {
      echo "Warning: Failed to create $target_dir" >&1
      return 1
    }
  fi

  # Copy core acme.sh files (non-subdirectory files only)
  find "$default_dir" -maxdepth 1 -type f | while IFS= read -r default_file; do
    filename=$(basename "$default_file")
    target_file="$target_dir/$filename"

    if [ ! -f "$target_file" ]; then
      cp "$default_file" "$target_file" 2>&1 || {
        echo "Warning: Failed to copy $filename" >&1
      }
      if echo "$filename" | grep -q '\.sh$'; then
        chmod +x "$target_file" 2>&1 || {
          echo "Warning: Failed to set execute permission on $filename" >&1
        }
      fi
      echo "  Copied: $filename" >&1
    fi
  done

  return 0
}

initialize_subdirectory() {
  local subdir_name=$1
  local default_subdir="/defaults/acme.sh/$subdir_name"
  local target_subdir="/acme.sh/$subdir_name"

  echo "Initializing $subdir_name subdirectory..." >&1

  if [ ! -d "$default_subdir" ]; then
    echo "Warning: Default $subdir_name directory not found at $default_subdir" >&1
    return 1
  fi

  if [ ! -d "$target_subdir" ]; then
    mkdir -p "$target_subdir" 2>&1 || {
      echo "Warning: Failed to create $target_subdir" >&1
      return 1
    }
  fi

  # Check if this subdirectory has any user files
  user_files_count=$(find "$target_subdir" -type f ! -name ".*" 2>/dev/null | wc -l)

  if [ "$user_files_count" -eq 0 ]; then
    echo "  No user files in $subdir_name, copying all defaults..." >&1
    cp -r "$default_subdir"/* "$target_subdir"/ 2>&1 || {
      echo "Warning: Failed to copy default $subdir_name files" >&1
    }
    find "$target_subdir" -name "*.sh" -exec chmod +x {} \; 2>&1 || {
      echo "Warning: Failed to set permissions on $subdir_name scripts" >&1
    }
  else
    echo "  User files detected in $subdir_name, symlinking missing defaults..." >&1
    sync_directory_files "$default_subdir" "$target_subdir" "$subdir_name"
  fi

  return 0
}

initialize_config_directory() {
  local default_dir="/defaults/config"
  local target_dir="/config"

  echo "Initializing config directory..." >&1

  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir" 2>&1 || {
      echo "Warning: Failed to create $target_dir" >&1
      return 1
    }
  fi

  if [ ! "$(ls -A "$target_dir" 2>/dev/null | grep -v '^lost+found$')" ]; then
    echo "  Config directory is empty, copying defaults..." >&1
    if [ -d "$default_dir" ]; then
      cp -r "$default_dir"/* "$target_dir"/ 2>&1 || {
        echo "Warning: Failed to copy config files" >&1
      }
    fi
  else
    echo "  Config directory has existing files, symlinking missing defaults..." >&1
    sync_directory_files "$default_dir" "$target_dir" "config"
  fi
}

initialize_certs_directory() {
  local default_dir="/defaults/certs"
  local target_dir="/certs"

  echo "Initializing certs directory..." >&1

  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir" 2>&1 || {
      echo "Warning: Failed to create $target_dir" >&1
      return 1
    }
  fi

  if [ ! "$(ls -A "$target_dir" 2>/dev/null | grep -v '^lost+found$')" ]; then
    echo "  Certs directory is empty, copying defaults..." >&1
    if [ -d "$default_dir" ]; then
      cp -r "$default_dir"/* "$target_dir"/ 2>&1 || {
        echo "Warning: Failed to copy cert directory files" >&1
      }
    fi
  else
    echo "  Certs directory exists with files, skipping initialization" >&1
  fi
}

setup_acme_symlink() {
  if [ -f "/acme.sh/acme.sh" ]; then
    echo "Creating acme.sh symlink..." >&1
    rm -f /usr/local/bin/acme.sh 2>&1 || true
    ln -s /acme.sh/acme.sh /usr/local/bin/acme.sh 2>&1 || {
      echo "Warning: Failed to create acme.sh symlink" >&1
    }
    chmod +x /usr/local/bin/acme.sh 2>&1 || {
      echo "Warning: Failed to set execute permission on symlink" >&1
    }
  else
    echo "Warning: /acme.sh/acme.sh not found, cannot create symlink" >&1
  fi
}

setup_cron_job() {
  if [ -f "/acme.sh/acme.sh" ] && ! crontab -l 2>/dev/null | grep -q acme.sh; then
    echo "Setting up acme.sh cron job..." >&1
    (
      crontab -l 2>/dev/null || true
      echo "0 0 * * * /acme.sh/acme.sh --cron --config-home /config > /proc/1/fd/1 2>/proc/1/fd/2"
    ) | crontab - 2>&1 || {
      echo "Warning: Failed to set up cron job" >&1
    }
  fi
}

# Main initialization sequence
main() {
  echo "Starting container initialization..." >&1

  # Initialize core directories
  initialize_config_directory
  initialize_certs_directory

  # Initialize acme.sh core files
  initialize_acme_core

  # Initialize acme.sh subdirectories (these can be mounted separately)
  for subdir in deploy dnsapi notify; do
    initialize_subdirectory "$subdir"
  done

  # Set up symlink and cron
  setup_acme_symlink
  setup_cron_job

  echo "Initialization complete." >&1
}

# Run main function
main
