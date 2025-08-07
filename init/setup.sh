#!/usr/bin/env sh
. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/logging.sh"

setup_acme_symlink() {
  if [ -f "$LE_BASE/acme.sh" ]; then
    echo "Creating acme.sh symlink..." >&1
    dryrun_log "Would remove existing symlink: /usr/local/bin/acme.sh"
    dryrun_log "Would create symlink: $LE_BASE/acme.sh → /usr/local/bin/acme.sh"
    dryrun_log "Would chmod +x on: /usr/local/bin/acme.sh"

    if [ "$DRYRUN" != "true" ]; then
      rm -f /usr/local/bin/acme.sh || true
      ln -s "$LE_BASE/acme.sh" /usr/local/bin/acme.sh || {
        echo "Warning: Failed to create acme.sh symlink" >&1
      }
      chmod +x /usr/local/bin/acme.sh || {
        echo "Warning: Failed to set execute permission on symlink" >&1
      }
    fi
  else
    echo "Warning: $LE_BASE/acme.sh not found, cannot create symlink" >&1
  fi
}

setup_cron_job() {
  if [ -f "$LE_BASE/acme.sh" ] && ! crontab -l 2>/dev/null | grep -q acme.sh; then
    echo "Setting up acme.sh cron job..." >&1
    dryrun_log "Would add cron job for: $LE_BASE/acme.sh --cron --config-home $LE_CONFIG_HOME"

    if [ "$DRYRUN" != "true" ]; then
      (crontab -l 2>/dev/null || true; echo "0 0 * * * $LE_BASE/acme.sh --cron --config-home $LE_CONFIG_HOME > /proc/1/fd/1 2>/proc/1/fd/2") | crontab - || {
        echo "Warning: Failed to set up cron job" >&1
      }
    fi
  fi
}
