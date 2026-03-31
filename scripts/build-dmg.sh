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
rm -f "$DMG_PATH"

# Use a unique volume name to avoid stale mount conflicts
VOL_NAME="Install Clautch"
VOL_PATH="/Volumes/$VOL_NAME"
TEMP_DMG="$BUILD_DIR/Clautch-temp.dmg"

# Ensure no stale mounts
if [ -d "$VOL_PATH" ]; then
    echo "    Ejecting stale volume"
    hdiutil detach "$VOL_PATH" -force 2>/dev/null || true
    sleep 1
fi

# Create a staging directory with the app and Applications alias
STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -a "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create a writable DMG from staging
hdiutil create -srcfolder "$STAGING" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 200m \
    "$TEMP_DMG"

# Mount it
MOUNT_OUTPUT=$(hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen)
DEVICE=$(echo "$MOUNT_OUTPUT" | tail -1 | awk '{print $1}')
echo "    Mounted at $VOL_PATH (device: $DEVICE)"

# Copy background image and hide the folder
mkdir -p "$VOL_PATH/.background"
cp "$SCRIPT_DIR/dmg-background.png" "$VOL_PATH/.background/background.png"

# Hide dotfiles using chflags (modern macOS) + SetFile (legacy fallback)
chflags hidden "$VOL_PATH/.background"
SetFile -a V "$VOL_PATH/.background" 2>/dev/null || true
if [ -d "$VOL_PATH/.fseventsd" ]; then
    chflags hidden "$VOL_PATH/.fseventsd"
    SetFile -a V "$VOL_PATH/.fseventsd" 2>/dev/null || true
fi

# Hide the file extension on the app
SetFile -a E "$VOL_PATH/Clautch.app" 2>/dev/null || true

# Configure Finder window via AppleScript
echo "    Configuring Finder window"
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 740, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.png"
        set position of item "Clautch.app" of container window to {150, 170}
        set position of item "Applications" of container window to {390, 170}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

# Ensure Finder flushes .DS_Store
sync

# Re-hide dotfiles after AppleScript (Finder can reset flags)
chflags hidden "$VOL_PATH/.background"
if [ -d "$VOL_PATH/.fseventsd" ]; then
    chflags hidden "$VOL_PATH/.fseventsd"
fi

# Detach
hdiutil detach "$DEVICE"

# Convert to compressed read-only DMG
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$TEMP_DMG"
rm -rf "$STAGING"

# ---------------------------------------------------------------------------
# Step 7 — Verify code signature
# ---------------------------------------------------------------------------
echo "==> Verifying code signature"
codesign --verify --deep --strict "$APP_PATH"
echo "    Code signature OK"

echo ""
echo "==> DMG created at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
