#!/usr/bin/env bash
# Code-sign an assembled bundle in the order Sparkle requires.
# Usage: scripts/sign.sh <App.app> [identity] [entitlements.plist]
#   identity defaults to "-" (ad-hoc). Set SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" for release.
set -euo pipefail
APP="${1:?app path}"
IDENTITY="${2:-${SIGN_IDENTITY:--}}"
ENTITLEMENTS="${3:-}"
# Ad-hoc builds skip the hardened runtime: library validation would refuse the re-signed
# Sparkle framework (no team id on either side). Real identities get runtime + timestamp.
if [ "$IDENTITY" = "-" ]; then
  OPTS=(--force --timestamp=none --sign -)
else
  OPTS=(--force --timestamp --options runtime --sign "$IDENTITY")
fi

FW="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$FW" ]; then
  codesign "${OPTS[@]}" "$FW/Versions/B/XPCServices/Installer.xpc"
  codesign "${OPTS[@]}" --preserve-metadata=entitlements "$FW/Versions/B/XPCServices/Downloader.xpc"
  codesign "${OPTS[@]}" "$FW/Versions/B/Autoupdate"
  codesign "${OPTS[@]}" "$FW/Versions/B/Updater.app"
  codesign "${OPTS[@]}" "$FW"
fi
if [ -n "$ENTITLEMENTS" ]; then
  codesign "${OPTS[@]}" --entitlements "$ENTITLEMENTS" "$APP"
else
  codesign "${OPTS[@]}" "$APP"
fi
codesign --verify --deep --strict "$APP"
echo "signed $APP with identity: $IDENTITY"
