#!/bin/zsh
set -euo pipefail

APP_NAME="KeyboardClean"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
ICON_PNG="$ROOT_DIR/Resources/AppIcon-1024.png"
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICON_ICNS="$ROOT_DIR/Resources/AppIcon.icns"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Generate a valid .icns from the 1024px source icon.
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_PNG" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"

xcrun swiftc \
  "$ROOT_DIR/Sources/main.swift" \
  -framework AppKit \
  -framework ApplicationServices \
  -o "$MACOS_DIR/$APP_NAME"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ICON_ICNS" "$RESOURCES_DIR/AppIcon.icns"

if [[ -z "$SIGN_IDENTITY" ]]; then
  # Prefer a stable signing identity so Accessibility permission doesn't reset each build.
  SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*"\(Apple Development[^"]*\)".*/\1/p' | head -n 1)"
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
  codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
  echo "Signed with: $SIGN_IDENTITY"
else
  echo "Warning: no stable signing identity found. Falling back to ad-hoc signing."
  echo "Set SIGN_IDENTITY to keep Accessibility permission across rebuilds."
  codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Built: $APP_DIR"
echo "Run: open '$APP_DIR'"
