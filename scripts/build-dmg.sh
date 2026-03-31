#!/bin/bash
set -euo pipefail

# Build a release DMG for Clautch with proper Developer ID signing
# Usage: ./scripts/build-dmg.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT/build"
SCHEME="Clautch"
APP_NAME="Clautch"
IDENTITY="Developer ID Application: Sophiie AI Pty Ltd (U2KP726DRL)"
ENTITLEMENTS="$ROOT/Clautch/Clautch-Release.entitlements"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
DMG_STAGING="$BUILD_DIR/dmg-staging"

# ---------------------------------------------------------------------------
# Step 1 — Clean
# ---------------------------------------------------------------------------
echo "==> Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ---------------------------------------------------------------------------
# Step 2 — Generate Xcode project
# ---------------------------------------------------------------------------
echo "==> Generating Xcode project"
cd "$ROOT"
xcodegen generate

# ---------------------------------------------------------------------------
# Step 3 — Archive with Developer ID
# ---------------------------------------------------------------------------
echo "==> Archiving release build"
xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    CODE_SIGN_IDENTITY="$IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_ENTITLEMENTS="$ENTITLEMENTS" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 4 — Remove embedded provisioning profile
# ---------------------------------------------------------------------------
echo "==> Removing embedded.provisionprofile"
rm -f "$APP_PATH/Contents/embedded.provisionprofile"

# ---------------------------------------------------------------------------
# Step 5 — Re-sign Sparkle framework internals (inside-out)
# ---------------------------------------------------------------------------
SPARKLE_FW="$APP_PATH/Contents/Frameworks/Sparkle.framework"

if [ -d "$SPARKLE_FW" ]; then
    echo "==> Re-signing Sparkle framework internals"

    # 5a — Individual binaries inside XPC bundles
    for BIN in Downloader Installer; do
        BINARY="$SPARKLE_FW/Versions/B/XPCServices/$BIN.xpc/Contents/MacOS/$BIN"
        if [ -f "$BINARY" ]; then
            echo "    Signing $BIN binary"
            codesign --force --sign "$IDENTITY" --timestamp --options runtime "$BINARY"
        fi
    done

    # 5b — Updater.app binary and Autoupdate standalone binary
    UPDATER_BIN="$SPARKLE_FW/Versions/B/Updater.app/Contents/MacOS/Updater"
    [ -f "$UPDATER_BIN" ] && codesign --force --sign "$IDENTITY" --timestamp --options runtime "$UPDATER_BIN"
    AUTOUPDATE_BIN="$SPARKLE_FW/Versions/B/Autoupdate"
    [ -f "$AUTOUPDATE_BIN" ] && codesign --force --sign "$IDENTITY" --timestamp --options runtime "$AUTOUPDATE_BIN"

    # 5c — XPC bundles
    for XPC in Downloader.xpc Installer.xpc; do
        BUNDLE="$SPARKLE_FW/Versions/B/XPCServices/$XPC"
        [ -d "$BUNDLE" ] && codesign --force --sign "$IDENTITY" --timestamp --options runtime "$BUNDLE"
    done

    # 5d — Updater.app bundle
    UPDATER_APP="$SPARKLE_FW/Versions/B/Updater.app"
    [ -d "$UPDATER_APP" ] && codesign --force --sign "$IDENTITY" --timestamp --options runtime "$UPDATER_APP"

    # 5e — Sparkle.framework itself
    echo "    Signing Sparkle.framework"
    codesign --force --sign "$IDENTITY" --timestamp --options runtime "$SPARKLE_FW"
else
    echo "WARNING: Sparkle.framework not found — skipping Sparkle re-signing"
fi

# 5f — Re-sign the main app with release entitlements
echo "==> Re-signing main app with release entitlements"
codesign --force --sign "$IDENTITY" \
    --timestamp \
    --options runtime \
    --entitlements "$ENTITLEMENTS" \
    "$APP_PATH"

# ---------------------------------------------------------------------------
# Step 6 — Create DMG
# ---------------------------------------------------------------------------
echo "==> Creating styled DMG"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

ditto "$APP_PATH" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"

# Create a temporary read-write DMG to style it
RW_DMG="$BUILD_DIR/Clautch-rw.dmg"
rm -f "$RW_DMG" "$DMG_PATH"

hdiutil create \
    -volname "Clautch" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDRW \
    -size 20m \
    "$RW_DMG"

rm -rf "$DMG_STAGING"

# Mount and style the DMG with Finder view options
MOUNT_DIR=$(hdiutil attach "$RW_DMG" -readwrite -noverify | tail -1 | awk '{print $NF}')
echo "    Mounted at: $MOUNT_DIR"

# Set Finder window properties via AppleScript
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "Clautch"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 640, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background color of viewOptions to {2570, 2570, 3084}
        set position of item "Clautch.app" of container window to {150, 160}
        set position of item "Applications" of container window to {390, 160}
        close
    end tell
end tell
APPLESCRIPT

# Ensure changes are flushed
sync
sleep 1

# Detach
hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
sleep 1

# Convert to compressed read-only DMG
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$RW_DMG"

# ---------------------------------------------------------------------------
# Step 7 — Verify code signature
# ---------------------------------------------------------------------------
echo "==> Verifying code signature"
codesign --verify --deep --strict "$APP_PATH"
echo "    Code signature OK"

echo ""
echo "==> DMG created at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
