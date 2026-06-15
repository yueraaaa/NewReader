#!/bin/bash
set -e
D="$(cd "$(dirname "$0")" && pwd)"
P="$(dirname "$D")"
S="$P/Sources/NewReaderMac"
B="$P/NewReader.app"
echo "=== Building Release ==="
cd "$P"
swift build -c release
rm -rf "$B"
mkdir -p "$B/Contents/MacOS" "$B/Contents/Resources"
cp "$P/.build/release/NewReaderMac" "$B/Contents/MacOS/"
cp "$S/Info.plist" "$B/Contents/"
# Mirror Secrets.plist into the user-level directory the app reads at runtime
# (~/Library/Application Support/NewReader/secrets.plist). The app falls back
# to this location when the bundled Info.plist doesn't have a real value,
# which makes local `swift run` work without baking secrets into the build.
USER_SECRETS_DIR="$HOME/Library/Application Support/NewReader"
if [ -f "$S/Secrets.plist" ]; then
    mkdir -p "$USER_SECRETS_DIR"
    if [ ! -f "$USER_SECRETS_DIR/secrets.plist" ]; then
        cp "$S/Secrets.plist" "$USER_SECRETS_DIR/secrets.plist"
        echo "Mirrored Secrets.plist to $USER_SECRETS_DIR/secrets.plist"
    fi

    # Merge secrets into Info.plist (Secrets.plist is gitignored).
    # Copy *all* keys verbatim so future additions (e.g. CloudflareTurnstileSitekey)
    # propagate automatically.
    python3 -c "
import plistlib
with open('$S/Secrets.plist', 'rb') as f:
    secrets = plistlib.load(f)
with open('$B/Contents/Info.plist', 'rb') as f:
    info = plistlib.load(f)
# Always-present keys (fail loud if missing).
for required in ('SupabaseURL', 'SupabasePublishableKey', 'FeedbackEmail'):
    if required not in secrets:
        raise SystemExit(f'Missing required key {required!r} in Secrets.plist')
    info[required] = secrets[required]
# Optional keys (merge if present).
for optional in ('CloudflareTurnstileSitekey',):
    if optional in secrets and secrets[optional]:
        info[optional] = secrets[optional]
with open('$B/Contents/Info.plist', 'wb') as f:
    plistlib.dump(info, f)
print('Secrets merged into Info.plist')
"
fi
cp "$S/AppIcon.icns" "$B/Contents/Resources/"
cp "$S/NewReader.entitlements" "$B/Contents/"
cp "$S/PrivacyInfo.xcprivacy" "$B/Contents/Resources/"
echo -n 'APPL????' > "$B/Contents/PkgInfo"
echo "=== Done: $B ==="
ls -lh "$B/Contents/MacOS/NewReaderMac"

# Create DMG for distribution
echo "=== Creating DMG ==="
rm -f "$P/NewReader.dmg"
hdiutil create -volname NewReader -srcfolder "$B" -ov -format UDZO "$P/NewReader.dmg" 2>/dev/null
echo "=== Done: $P/NewReader.dmg ==="
ls -lh "$P/NewReader.dmg"

