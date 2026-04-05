#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUILD="$PROJECT_DIR/build/DerivedData/Build/Products/Release/Flourish.app"
DMG_OUT="$PROJECT_DIR/Flourish.dmg"
STAGING="/tmp/Flourish-dmg-staging"

echo "==> Building Flourish (Release)..."
xcodebuild \
  -project "$PROJECT_DIR/Flourish.xcodeproj" \
  -scheme Flourish \
  -configuration Release \
  -derivedDataPath "$PROJECT_DIR/build/DerivedData" \
  build | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "^$" || true

# Verify the build actually succeeded
if [ ! -d "$APP_BUILD" ]; then
  echo "ERROR: Build failed — app not found at $APP_BUILD"
  exit 1
fi

echo "==> Packaging DMG..."
rm -rf "$STAGING" "$DMG_OUT"
mkdir -p "$STAGING"
cp -R "$APP_BUILD" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "Flourish" -srcfolder "$STAGING" -ov -format UDRW /tmp/Flourish-tmp.dmg -quiet
hdiutil convert /tmp/Flourish-tmp.dmg -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" -quiet

rm -rf "$STAGING" /tmp/Flourish-tmp.dmg

echo "==> Done: $DMG_OUT ($(du -sh "$DMG_OUT" | cut -f1))"
