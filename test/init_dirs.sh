#!/bin/sh
# test/init_dirs.sh

echo "📁 Initializing dry-run directories..."

mkdir -p "$LE_BASE"
mkdir -p "$LE_WORKING_DIR"
mkdir -p "$LE_CONFIG_HOME"
mkdir -p "$LE_CERT_HOME"

echo "✅ Dry-run directories ready:"
echo "  - LE_BASE=$LE_BASE"
echo "  - LE_WORKING_DIR=$LE_WORKING_DIR"
echo "  - LE_CONFIG_HOME=$LE_CONFIG_HOME"
echo "  - LE_CERT_HOME=$LE_CERT_HOME"
