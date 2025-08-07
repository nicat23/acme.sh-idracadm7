#!/usr/bin/env sh
. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/init_dirs.sh"

initialize_base_dirs() {
  echo "Initializing base directories under $LE_BASE..." >&1

  local total_created=0
  local total_skipped=0
  local total_replaced=0
  local total_fixed_exec=0

  for subdir in deploy dnsapi notify; do
    # Capture output
    output=$(initialize_directory "acme.sh/$subdir" "$subdir" 2>&1)
    echo "$output"

    # Parse summary lines
    created=$(echo "$output" | grep -Eo 'Symlinks created: [0-9]+' | awk '{print $3}')
    skipped=$(echo "$output" | grep -Eo 'Skipped \(existing files\): [0-9]+' | awk '{print $4}')
    replaced=$(echo "$output" | grep -Eo 'Replaced broken symlinks: [0-9]+' | awk '{print $4}')
    fixed_exec=$(echo "$output" | grep -Eo 'Fixed permissions: [0-9]+' | awk '{print $3}')

    total_created=$((total_created + created))
    total_skipped=$((total_skipped + skipped))
    total_replaced=$((total_replaced + replaced))
    total_fixed_exec=$((total_fixed_exec + fixed_exec))
  done

  echo "🧾 Grand Total Summary:"
  echo "  ✅ Symlinks created: $total_created"
  echo "  ⚠️  Skipped (existing files): $total_skipped"
  echo "  🔁 Replaced broken symlinks: $total_replaced"
  echo "  🛠️  Fixed permissions: $total_fixed_exec"
}

initialize_base_dirs
