#!/usr/bin/env bash
set -euo pipefail

# Match the framework version used by tauri-plugin-sparkle-updater 0.3.0.
ROOT="$(git rev-parse --show-toplevel)"
VERSION=2.9.6
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
curl --fail --location --retry 3 \
  "https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz" \
  --output "$TEMP_DIR/sparkle.tar.xz"
tar -xf "$TEMP_DIR/sparkle.tar.xz" -C "$TEMP_DIR"
ditto "$TEMP_DIR/Sparkle.framework" "$ROOT/src-tauri/Sparkle.framework"
mkdir -p "$ROOT/src-tauri/sparkle-tools"
ditto "$TEMP_DIR/bin" "$ROOT/src-tauri/sparkle-tools"
