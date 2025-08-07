#!/usr/bin/env sh
resolve_paths() {
  local subpath=$1
  echo "$LE_WORKING_DIR/$subpath $LE_BASE/$subpath"
}
