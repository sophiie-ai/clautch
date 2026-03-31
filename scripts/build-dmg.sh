#!/bin/bash
set -euo pipefail

# Build a release DMG for Clautch
# Usage: ./scripts/build-dmg.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT/build"
SCHEME="Clautch"
APP_NAME="Clautch"

echo "==> Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Generating Xcode project"
cd "$ROOT"
xcodegen generate

echo "==> Building release archive"
xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=U2KP726DRL

echo "==> Exporting archive"
xcodebuild \
    -exportArchive \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    -exportPath "$BUILD_DIR/export" \
    -exportOptionsPlist "$SCRIPT_DIR/ExportOptions.plist" \
    -allowProvisioningUpdates

APP_PATH="$BUILD_DIR/export/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
fi

echo "==> Creating DMG"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo ""
echo "==> DMG created at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"

# Optional: notarize
if [ "${NOTARIZE:-0}" = "1" ]; then
    echo "==> Submitting for notarization"
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "notarytool" \
        --wait
    echo "==> Stapling"
    xcrun stapler staple "$DMG_PATH"
    echo "==> Notarization complete"
fi
