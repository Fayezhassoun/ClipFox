#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
APP_NAME="ClipFox"
BUNDLE_ID="com.fayez.clipfox"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "==> Building $APP_NAME release executable…"
swift build -c release --product "$APP_NAME"

BIN_DIR=$(swift build -c release --product "$APP_NAME" --show-bin-path)
EXEC_SRC="$BIN_DIR/$APP_NAME"

if [ ! -f "$EXEC_SRC" ]; then
  echo "Error: executable not found at $EXEC_SRC"
  exit 1
fi

echo "==> Creating .app bundle at $APP_PATH…"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$EXEC_SRC" "$APP_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 Fayez Hassoun. All rights reserved.</string>
</dict>
</plist>
PLIST

cp Config/ClipFox-iCloud.entitlements "$APP_PATH/Contents/Resources/ClipFox.entitlements"

echo "==> Ad-hoc codesigning…"
codesign --force --deep --sign - \
  --entitlements Config/ClipFox-iCloud.entitlements \
  --options runtime \
  "$APP_PATH" 2>&1 | tail -5 || true

# Fallback without hardened runtime if the above fails (ad-hoc + hardened
# is fine, but some macOS versions complain about specific entitlements).
if ! codesign -dv "$APP_PATH" >/dev/null 2>&1; then
  codesign --force --deep --sign - \
    --entitlements Config/ClipFox-iCloud.entitlements \
    "$APP_PATH"
fi

echo "==> Verifying signature…"
codesign -dv "$APP_PATH" 2>&1 | head -5
spctl -a -vv "$APP_PATH" 2>&1 | head -3 || true

echo "==> Built: $APP_PATH"
