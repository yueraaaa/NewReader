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
# Merge Supabase secrets into Info.plist (Secrets.plist is gitignored)
if [ -f "$S/Secrets.plist" ]; then
    python3 -c "
import plistlib
with open('$S/Secrets.plist', 'rb') as f:
    secrets = plistlib.load(f)
with open('$B/Contents/Info.plist', 'rb') as f:
    info = plistlib.load(f)
info['SupabaseURL'] = secrets['SupabaseURL']
info['SupabasePublishableKey'] = secrets['SupabasePublishableKey']
info['FeedbackEmail'] = secrets['FeedbackEmail']
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

