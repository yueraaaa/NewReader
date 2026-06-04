#!/bin/bash
# Sign the appcast with Sparkle's EdDSA key.
# Prerequisites:
#   1. brew install sparkle
#   2. Generate key: ./bin/generate_keys
#   3. Move sparkle_ed.pem to this project root
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?Usage: $0 <version>}"
echo "Signing appcast for v$VERSION..."
generate_appcast --ed-key-file sparkle_ed.pem website/
echo "Done. Deploy with: npx netlify deploy --dir=website --prod"
