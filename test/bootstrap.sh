#!/usr/bin/env sh

DEFAULT_BASE="/tmp/test/defaults/acme.sh"
TARGET_BASE="/tmp/test/acme"

mkdir -p "$DEFAULT_BASE/deploy" "$DEFAULT_BASE/dnsapi" "$DEFAULT_BASE/notify"

# Create dummy default files
for dir in deploy dnsapi notify; do
  for file in example.sh helper.sh; do
    path="$DEFAULT_BASE/$dir/$file"
    echo "#!/usr/bin/env sh\n# Default $file in $dir" > "$path"
    chmod +x "$path"
  done
done

# Simulate user bind mount: real file that should not be overwritten
mkdir -p "$TARGET_BASE/deploy"
echo "#!/usr/bin/env sh\n# USER OVERRIDE: do not replace" > "$TARGET_BASE/deploy/example.sh"
chmod +x "$TARGET_BASE/deploy/example.sh"

# Simulate broken symlink
ln -s /nonexistent/path "$TARGET_BASE/deploy/broken.sh"

# Simulate bad permissions: file exists but not executable
echo "#!/usr/bin/env sh\n# Not executable" > "$TARGET_BASE/deploy/unexecutable.sh"
chmod -x "$TARGET_BASE/deploy/unexecutable.sh"

echo "✅ Dummy defaults created under /tmp/test/defaults"
echo "⚠️  Simulated user bind mount: /tmp/test/acme/deploy/example.sh"
echo "⚠️  Simulated broken symlink: /tmp/test/acme/deploy/broken.sh → /nonexistent/path"
echo "⚠️  Simulated bad permissions: /tmp/test/acme/deploy/unexecutable.sh"
