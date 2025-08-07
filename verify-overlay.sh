#!/usr/bin/env bash
set -euo pipefail

for dir in /acme/deploy /acme/dnsapi /acme/notify; do
  echo "📂 Verifying overlay in $dir"
  for f in "$dir"/*.sh; do
    base="$(basename "$f")"
    origin_file="$dir/.origin/$base"
    if [[ -f "$origin_file" ]]; then
      origin="$(cat "$origin_file")"
      echo "  ✅ $base ← $origin"
    else
      echo "  ❓ $base ← unknown origin"
    fi
  done
done
