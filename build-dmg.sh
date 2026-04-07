#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Show the last generated DMG version (if any)
LAST_DMG=$(ls "$PROJECT_DIR"/flourish-*.dmg 2>/dev/null | sort -V | tail -1)
if [ -n "$LAST_DMG" ]; then
  LAST_VERSION=$(basename "$LAST_DMG" .dmg | sed 's/^flourish-//')
  echo "Last generated version: $LAST_VERSION"
else
  echo "No previous DMG found."
fi

# Prompt for the new version
read -rp "Enter version to build (e.g. 1.0-beta, 1.1, 2.0): " VERSION
if [ -z "$VERSION" ]; then
  echo "ERROR: Version cannot be empty."
  exit 1
fi

APP_BUILD="$PROJECT_DIR/build/DerivedData/Build/Products/Release/flourish.app"
DMG_OUT="$PROJECT_DIR/flourish-$VERSION.dmg"
STAGING="/tmp/flourish-dmg-staging"
TMP_DMG="/tmp/flourish-tmp.dmg"

# DMG window dimensions (logical pixels, 1x)
WIN_W=660
WIN_H=400

echo "==> Stamping version $VERSION into Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
  "$PROJECT_DIR/flourish/Info.plist"

echo "==> Regenerating .xcodeproj from project.yml..."
make generate

echo "==> Building flourish (Release)..."
xcodebuild \
  -project "$PROJECT_DIR/flourish.xcodeproj" \
  -scheme flourish \
  -configuration Release \
  -derivedDataPath "$PROJECT_DIR/build/DerivedData" \
  build | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "^$" || true

# Verify the build actually succeeded
if [ ! -d "$APP_BUILD" ]; then
  echo "ERROR: Build failed — app not found at $APP_BUILD"
  exit 1
fi

echo "==> Packaging DMG..."
rm -rf "$STAGING" "$DMG_OUT" "$TMP_DMG"
mkdir -p "$STAGING/.background"
cp -R "$APP_BUILD" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Background image
BG_SRC="$PROJECT_DIR/assets/dmg-background.png"
if [ -f "$BG_SRC" ]; then
  cp "$BG_SRC" "$STAGING/.background/background.png"
  cp "$BG_SRC" "$STAGING/.background/background@2x.png"
fi

# Volume icon
ICNS_SRC="$APP_BUILD/Contents/Resources/AppIcon.icns"
if [ -f "$ICNS_SRC" ]; then
  cp "$ICNS_SRC" "$STAGING/.VolumeIcon.icns"
  SetFile -a C "$STAGING" 2>/dev/null || true
fi

# Create writable image (slightly oversized to leave room for AppleScript tweaks)
hdiutil create -volname "flourish" -srcfolder "$STAGING" -ov -format UDRW \
  -size $((WIN_W * WIN_H / 100))k "$TMP_DMG" -quiet

# Mount and customise the window via AppleScript
MOUNT_INFO=$(hdiutil attach "$TMP_DMG" -readwrite -nobrowse -noverify)
MOUNT_DEV=$(echo "$MOUNT_INFO" | awk 'NR==1 {print $1}')
MOUNT_POINT=$(echo "$MOUNT_INFO" | awk 'END {print $NF}')

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "flourish"
    open

    -- Window size and position
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 100, $((200 + WIN_W)), $((100 + WIN_H))}

    -- Icon view options
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 96

    -- Background image
    set background picture of theViewOptions to file ".background:background.png"

    -- Icon positions  (x=165 app, x=495 Applications — centred in their halves)
    set position of item "flourish.app"   of container window to {165, 160}
    set position of item "Applications"   of container window to {495, 160}

    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT

# Set volume icon bit on the mounted volume too
SetFile -a C "$MOUNT_POINT" 2>/dev/null || true

# Flush and detach
sync
hdiutil detach "$MOUNT_DEV" -quiet

# Convert to compressed read-only image
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" -quiet

rm -rf "$STAGING" "$TMP_DMG"

echo "==> Done: $DMG_OUT ($(du -sh "$DMG_OUT" | cut -f1))"
