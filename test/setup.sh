#!/bin/sh
# test/setup.sh

echo "🔧 Simulating setup artifacts..."

DEPLOY_DIR="$LE_BASE/deploy"
mkdir -p "$DEPLOY_DIR"

# Simulate user bind mount
touch "$DEPLOY_DIR/example.sh"
echo "⚠️  Simulated user bind mount: $DEPLOY_DIR/example.sh"

# Simulate broken symlink
ln -sf /nonexistent/path "$DEPLOY_DIR/broken.sh"
echo "⚠️  Simulated broken symlink: $DEPLOY_DIR/broken.sh → /nonexistent/path"

# Simulate bad permissions
touch "$DEPLOY_DIR/unexecutable.sh"
chmod -x "$DEPLOY_DIR/unexecutable.sh"
echo "⚠️  Simulated bad permissions: $DEPLOY_DIR/unexecutable.sh"
