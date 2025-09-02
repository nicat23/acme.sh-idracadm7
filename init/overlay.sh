#!/usr/bin/env sh
# This script overlays custom scripts from /hooks into the acme.sh directories.
# For this to work, you should have directories like /hooks/deploy, /hooks/dnsapi, etc.
# containing your custom .sh files.
set -e  # Exit on any error
OVERLAY_TYPES="deploy dnsapi notify"
echo "🔗 Looking for custom scripts in /hooks to link them into ${LE_WORKING_DIR}"

# Verify LE_WORKING_DIR exists and is accessible
if [ ! -d "$LE_WORKING_DIR" ]; then
    echo "❌ Error: LE_WORKING_DIR ($LE_WORKING_DIR) does not exist"
    exit 1
fi

# Check if /hooks directory exists
if [ ! -d "/hooks" ]; then
    echo "ℹ️  No /hooks directory found, skipping overlay setup"
    exit 0
fi

link_count=0
for NAME in $OVERLAY_TYPES; do
    HOOK_DIR="/hooks/$NAME"
    TARGET_PARENT_DIR="${LE_WORKING_DIR}/${NAME}"

    if [ ! -d "$HOOK_DIR" ]; then
        # Just skipping, this is not an error. The user may not have custom scripts for this type.
        echo "ℹ️  No custom $NAME scripts found in $HOOK_DIR, skipping..."
        continue
    fi

    echo "➡️  Found custom scripts in $HOOK_DIR. Linking them..."

    # Ensure the target directory exists
    if [ ! -d "$TARGET_PARENT_DIR" ]; then
        echo "⚠️  Warning: Target directory ${TARGET_PARENT_DIR} does not exist. Creating it..."
        mkdir -p "$TARGET_PARENT_DIR"
        # Set proper permissions
        chmod 755 "$TARGET_PARENT_DIR"
    fi

    # Check if there are actually .sh files in the directory
    if ! ls "$HOOK_DIR"/*.sh >/dev/null 2>&1; then
        echo "ℹ️  No .sh files found in $HOOK_DIR, skipping..."
        continue
    fi

    for SCRIPT in "$HOOK_DIR"/*.sh; do
        if [ -f "$SCRIPT" ]; then
            SCRIPT_NAME=$(basename "$SCRIPT")
            TARGET_FILE="${TARGET_PARENT_DIR}/${SCRIPT_NAME}"
            
            # Validate script name (basic security check)
            case "$SCRIPT_NAME" in
                *[!a-zA-Z0-9._-]*)
                    echo "⚠️  Warning: Skipping script with unsafe name: $SCRIPT_NAME"
                    continue
                    ;;
            esac
            
            # Create symbolic link with force overwrite
            if ln -sf "$SCRIPT" "$TARGET_FILE"; then
                # Make sure the linked script is executable
                sudo chmod +x "$TARGET_FILE"
                echo "✅ Linked $SCRIPT to $TARGET_FILE"
                link_count=$((link_count + 1))
            else
                echo "❌ Failed to link $SCRIPT to $TARGET_FILE"
            fi
        fi
    done
done

if [ $link_count -eq 0 ]; then
    echo "ℹ️  No custom scripts were linked"
else
    echo "✅ Successfully linked $link_count custom script(s)"
fi

echo "🏁 Finished container initialization."
