#!/bin/bash
set -euo pipefail

# Full release workflow for Clautch
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.2.0

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version> [release-notes-file]"
    echo "Example: $0 0.2.0 RELEASE_NOTES.md"
    exit 1
fi

VERSION="$1"
NOTES_FILE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT/build"
DMG_PATH="$BUILD_DIR/Clautch.dmg"
ZIP_PATH="$BUILD_DIR/Clautch.zip"
APPCAST="$ROOT/public/appcast.xml"
REPO="sophiie-ai/clautch"
TAG="v$VERSION"

echo "============================================"
echo "  Releasing Clautch $TAG"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# Step 1 — Build DMG
# ---------------------------------------------------------------------------
echo "==> Step 1: Building DMG"
"$SCRIPT_DIR/build-dmg.sh"

if [ ! -f "$DMG_PATH" ]; then
    echo "ERROR: DMG not found at $DMG_PATH"
    exit 1
fi
if [ ! -f "$ZIP_PATH" ]; then
    echo "ERROR: ZIP not found at $ZIP_PATH"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 2 — Notarize
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 2: Notarizing DMG"
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "notarytool" \
    --wait

# ---------------------------------------------------------------------------
# Step 3 — Staple
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 3: Stapling notarization ticket"
xcrun stapler staple "$DMG_PATH"

# ---------------------------------------------------------------------------
# Step 4 — Sign for Sparkle (EdDSA)
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 4: Signing ZIP for Sparkle updates"

SIGN_UPDATE=""
# Search DerivedData for the Sparkle sign_update tool
for CANDIDATE in ~/Library/Developer/Xcode/DerivedData/Clautch-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update; do
    if [ -f "$CANDIDATE" ]; then
        SIGN_UPDATE="$CANDIDATE"
        break
    fi
done

if [ -z "$SIGN_UPDATE" ]; then
    echo "ERROR: sign_update not found in DerivedData. Build the project in Xcode first."
    exit 1
fi

SPARKLE_OUTPUT=$("$SIGN_UPDATE" "$ZIP_PATH")
echo "    $SPARKLE_OUTPUT"

# Parse signature and length from sign_update output
# Output format: sparkle:edSignature="..." length="..."
SIGNATURE=$(echo "$SPARKLE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
ZIP_LENGTH=$(stat -f%z "$ZIP_PATH")

if [ -z "$SIGNATURE" ]; then
    echo "ERROR: Failed to extract Sparkle signature"
    exit 1
fi

echo "    Signature: $SIGNATURE"
echo "    Length: $ZIP_LENGTH bytes"

# ---------------------------------------------------------------------------
# Step 5 — GitHub release
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 5: Creating GitHub release $TAG"

# Delete existing release and tag if present
if gh release view "$TAG" --repo "$REPO" &>/dev/null; then
    echo "    Deleting existing release $TAG"
    gh release delete "$TAG" --repo "$REPO" --yes --cleanup-tag
fi

if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
    gh release create "$TAG" \
        --repo "$REPO" \
        --title "Clautch $TAG" \
        --notes-file "$NOTES_FILE" \
        "$DMG_PATH" "$ZIP_PATH"
else
    gh release create "$TAG" \
        --repo "$REPO" \
        --title "Clautch $TAG" \
        --generate-notes \
        "$DMG_PATH" "$ZIP_PATH"
    echo "    WARNING: No release notes file provided — used auto-generated notes"
fi

echo "    Release created: https://github.com/$REPO/releases/tag/$TAG"

# ---------------------------------------------------------------------------
# Step 6 — Update appcast.xml
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 6: Updating appcast.xml"

PUB_DATE=$(date -R)

# Read build number from Info.plist (CFBundleVersion)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$ROOT/Clautch/Info.plist")
echo "    Marketing version: $VERSION, Build number: $BUILD_NUMBER"

# Build the new <item> block
# sparkle:version = build number (compared against CFBundleVersion)
# sparkle:shortVersionString = marketing version (displayed to user)
NEW_ITEM="    <item>
      <title>Version $VERSION</title>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>$PUB_DATE</pubDate>
      <enclosure
        url=\"https://github.com/$REPO/releases/download/$TAG/Clautch.zip\"
        length=\"$ZIP_LENGTH\"
        type=\"application/octet-stream\"
        sparkle:edSignature=\"$SIGNATURE\" />
    </item>"

# Replace everything between <channel>...</channel> with just the latest item
# This keeps a single-item feed (latest release only)
python3 -c "
import re, sys

appcast = open('$APPCAST', 'r').read()

new_item = '''$NEW_ITEM'''

# Replace all existing <item>...</item> blocks with the new one
appcast = re.sub(
    r'(<language>en</language>\n).*?(  </channel>)',
    r'\1' + new_item + r'\n\2',
    appcast,
    flags=re.DOTALL
)

open('$APPCAST', 'w').write(appcast)
print('    appcast.xml updated')
"

# ---------------------------------------------------------------------------
# Step 7 — Commit and push
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 7: Committing and pushing"
cd "$ROOT"
git add public/appcast.xml
git commit -m "release: update appcast for $TAG"
# Try SSH first, fall back to HTTPS
git push 2>/dev/null || git push https://github.com/$REPO.git main

# ---------------------------------------------------------------------------
# Step 8 — Deploy to Vercel
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 8: Deploying to Vercel"
cd "$ROOT"
vercel --prod

echo ""
echo "============================================"
echo "  Clautch $TAG released successfully!"
echo "============================================"
echo ""
echo "  DMG: $DMG_PATH"
echo "  Release: https://github.com/$REPO/releases/tag/$TAG"
echo "  Appcast: https://clautch.app/appcast.xml"
echo ""
