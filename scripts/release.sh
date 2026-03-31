#!/bin/bash
set -euo pipefail

# Full release workflow: build DMG, sign for Sparkle, update appcast
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 0.2.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT/build"
SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData/Clautch-*/SourcePackages/artifacts/sparkle/Sparkle/bin -maxdepth 0 2>/dev/null | head -1)"

VERSION="${1:-$(defaults read "$ROOT/Clautch/Info.plist" CFBundleShortVersionString)}"
echo "==> Releasing Clautch v$VERSION"

# Step 1: Build DMG
"$SCRIPT_DIR/build-dmg.sh"

DMG_PATH="$BUILD_DIR/Clautch.dmg"
if [ ! -f "$DMG_PATH" ]; then
    echo "ERROR: DMG not found"
    exit 1
fi

# Step 2: Sign DMG with Sparkle EdDSA key
if [ -n "$SPARKLE_BIN" ] && [ -f "$SPARKLE_BIN/sign_update" ]; then
    echo "==> Signing DMG for Sparkle"
    SIGNATURE=$("$SPARKLE_BIN/sign_update" "$DMG_PATH" 2>&1 | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
    echo "    Signature: $SIGNATURE"
    echo "    Size: $DMG_SIZE bytes"
else
    echo "WARNING: Sparkle sign_update not found — skipping signature"
    SIGNATURE=""
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
fi

# Step 3: Print appcast item to add
DATE=$(date -R)
echo ""
echo "==> Add this to public/appcast.xml inside <channel>:"
echo ""
cat <<ITEM
    <item>
      <title>Version $VERSION</title>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>$DATE</pubDate>
      <enclosure
        url="https://github.com/sophiie-ai/clautch/releases/download/v$VERSION/Clautch.dmg"
        length="$DMG_SIZE"
        type="application/octet-stream"
        sparkle:edSignature="$SIGNATURE" />
    </item>
ITEM

echo ""
echo "==> Next steps:"
echo "   1. Create GitHub release v$VERSION and attach build/Clautch.dmg"
echo "   2. Add the <item> above to public/appcast.xml"
echo "   3. Deploy to Vercel: git push (or vercel --prod)"
