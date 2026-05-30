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
cp "$S/AppIcon.icns" "$B/Contents/Resources/"
echo -n 'APPL????' > "$B/Contents/PkgInfo"
echo "=== Done: $B ==="
ls -lh "$B/Contents/MacOS/NewReaderMac"
