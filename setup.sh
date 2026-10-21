#!/bin/bash
# Lumina one-step setup (run on your Mac from inside the Lumina folder).
#
#   ./setup.sh com.yourname YOURTEAMID
#
#   com.yourname  = reverse-domain prefix you own, e.g. com.texaslightworks
#   YOURTEAMID    = 10-character Team ID from developer.apple.com → Membership (optional)
set -e
cd "$(dirname "$0")"

PREFIX="$1"
TEAM="$2"

if [ -z "$PREFIX" ]; then
  echo "Usage: ./setup.sh com.yourname [TEAMID]"
  exit 1
fi

echo "→ Setting bundle prefix to $PREFIX"
grep -rl "com\.luminamanifestation" --include="*.swift" --include="*.yml" --include="*.storekit" . \
  | xargs perl -pi -e "s/com\.luminamanifestation/$PREFIX/g"

if [ -n "$TEAM" ]; then
  echo "→ Setting Team ID to $TEAM"
  perl -pi -e "s/DEVELOPMENT_TEAM: \"\"/DEVELOPMENT_TEAM: \"$TEAM\"/" project.yml
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "→ Installing XcodeGen with Homebrew"
    brew install xcodegen
  else
    echo "XcodeGen is required. Install Homebrew (https://brew.sh), then run: brew install xcodegen"
    exit 1
  fi
fi

echo "→ Generating Lumina.xcodeproj"
xcodegen generate
open Lumina.xcodeproj
echo "✓ Done. In Xcode choose the 'Lumina' scheme and an iPhone simulator, then press ⌘R."
