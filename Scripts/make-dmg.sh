#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ClipFox"
VERSION="${VERSION:-0.1.0}"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$BUILD_DIR/dmg-staging"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH not found. Run Scripts/build-app.sh first."
  exit 1
fi

echo "==> Staging DMG contents…"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG at $DMG_PATH…"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR"

SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo "==> Built: $DMG_PATH ($SIZE)"
