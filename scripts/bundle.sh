#!/usr/bin/env bash
# Assemble DollarApple.app from a SwiftPM release build.
# Usage: scripts/bundle.sh direct|store <out-dir> [version] [build]
set -euo pipefail
VARIANT="${1:?direct|store}"
OUT="${2:?out dir}"
VERSION="${3:-0.0.0}"
BUILD_NUM="${4:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/.build/release"
APP="$OUT/DollarApple.app"

case "$VARIANT" in
  direct) EXE="DollarApple";      PLIST="$ROOT/Packaging/Info.plist" ;;
  store)  EXE="DollarAppleStore"; PLIST="$ROOT/Packaging/Info-Store.plist" ;;
  *) echo "unknown variant $VARIANT" >&2; exit 2 ;;
esac

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BUILD/$EXE" "$APP/Contents/MacOS/DollarApple"
cp -R "$BUILD/DollarApple_DollarAppleUI.bundle" "$APP/Contents/Resources/"
# SwiftPM lowercases .lproj names; restore the canonical BCP 47 casing.
for d in "$APP"/Contents/Resources/DollarApple_DollarAppleUI.bundle/*.lproj; do
  base="$(basename "$d" .lproj)"
  case "$base" in pt-br) mv "$d" "$(dirname "$d")/pt-BR.lproj" ;; esac
done
cp "$ROOT/Packaging/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD_NUM/" "$PLIST" > "$APP/Contents/Info.plist"
echo -n "APPL????" > "$APP/Contents/PkgInfo"

if [ "$VARIANT" = "direct" ]; then
  FW="$(find "$ROOT/.build/artifacts" -type d -name Sparkle.framework -path '*macos*' | head -1)"
  [ -n "$FW" ] || { echo "Sparkle.framework not found under .build/artifacts; run swift build first" >&2; exit 1; }
  ditto "$FW" "$APP/Contents/Frameworks/Sparkle.framework"
else
  rmdir "$APP/Contents/Frameworks"
fi
echo "bundled $APP ($VARIANT, $VERSION build $BUILD_NUM)"
