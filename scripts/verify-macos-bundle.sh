#!/usr/bin/env bash
set -euo pipefail

APP="src-tauri/target/universal-apple-darwin/release/bundle/macos/Android Tools.app"
PLIST="$APP/Contents/Info.plist"
read_plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST"; }
test "$(read_plist CFBundleIdentifier)" = 'com.example.androidTools'
test "$(read_plist CFBundleShortVersionString)" = "$(node -p "require('./src-tauri/tauri.conf.json').version")"
test "$(read_plist CFBundleVersion)" = "$(node -p "require('./src-tauri/tauri.conf.json').bundle.macOS.bundleVersion")"
test "$(read_plist LSMinimumSystemVersion)" = "$(node -p "require('./src-tauri/tauri.conf.json').bundle.macOS.minimumSystemVersion")"
test "$(read_plist SUFeedURL)" = 'https://raw.githubusercontent.com/ThomasBernard03/AndroidTools/refs/heads/main/appcast.xml'
test "$(read_plist SUPublicEDKey)" = 'z9EBcFEFrJ5Bi6oiODtO2k6fo7X61gTEKmiuG3+Qxwg='
test "$(read_plist SUEnableAutomaticChecks)" = 'true'
test -d "$APP/Contents/Frameworks/Sparkle.framework"
EXECUTABLE="$APP/Contents/MacOS/$(read_plist CFBundleExecutable)"
lipo "$EXECUTABLE" -verify_arch arm64 x86_64
for ARCH in arm64 x86_64; do
  if [ "$ARCH" = arm64 ]; then TARGET=aarch64-apple-darwin; else TARGET=x86_64-apple-darwin; fi
  SYMBOLS="src-tauri/target/$TARGET/release/android-tools.dSYM"
  test -d "$SYMBOLS"
  BINARY_UUID=$(xcrun dwarfdump --uuid --arch "$ARCH" "$EXECUTABLE" | cut -d' ' -f2)
  SYMBOL_UUID=$(xcrun dwarfdump --uuid "$SYMBOLS" | cut -d' ' -f2)
  test -n "$BINARY_UUID"
  test "$BINARY_UUID" = "$SYMBOL_UUID"
  otool -arch "$ARCH" -l "$EXECUTABLE" | grep -F '@executable_path/../Frameworks'
  FLAGS=$(codesign --display --verbose=4 --arch "$ARCH" "$EXECUTABLE" 2>&1)
  # Ad-hoc signed frameworks have no Apple Team ID: library validation must stay off.
  if [[ "$FLAGS" == *runtime* || "$FLAGS" == *library-validation* ]]; then
    echo 'Ad-hoc releases must not enforce hardened runtime or library validation.' >&2
    exit 1
  fi
done
codesign --verify --deep --strict "$APP"
