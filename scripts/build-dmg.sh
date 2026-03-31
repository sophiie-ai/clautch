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

# Requires: brew install create-dmg
if ! command -v create-dmg &>/dev/null; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

create-dmg \
    --volname "Install Clautch" \
    --background "$SCRIPT_DIR/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "Clautch.app" 150 170 \
    --hide-extension "Clautch.app" \
    --app-drop-link 390 170 \
    --text-size 13 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH"

# ---------------------------------------------------------------------------
# Step 7 — Verify code signature
# ---------------------------------------------------------------------------
echo "==> Verifying code signature"
codesign --verify --deep --strict "$APP_PATH"
echo "    Code signature OK"

echo ""
echo "==> DMG created at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
