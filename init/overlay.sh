#!/usr/bin/env sh

OVERLAY_TYPES="deploy dnsapi notify"
for NAME in $OVERLAY_TYPES; do
  if [ -d "/hooks/$NAME" ]; then
    for SCRIPT in /hooks/"$NAME"/*.sh; do
      if [ -f "$SCRIPT" ]; then
        ln -s "$SCRIPT" "${LE_WORKING_DIR}/${NAME}/$(basename "$SCRIPT")"
        echo "linked $SCRIPT to ${LE_WORKING_DIR}/${NAME}/$(basename "$SCRIPT")"
      fi
    done
  fi
done
