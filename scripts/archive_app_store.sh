#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/KeyboardClean.xcodeproj"
SCHEME="KeyboardClean"
ARCHIVE_PATH="$ROOT_DIR/build/KeyboardClean.xcarchive"
EXPORT_PATH="$ROOT_DIR/build/AppStoreExport"
EXPORT_TEMPLATE="$ROOT_DIR/Config/ExportOptions-AppStore.plist.template"
EXPORT_PLIST="$ROOT_DIR/build/ExportOptions-AppStore.plist"
ARCHIVE_APP_RESOURCES="$ARCHIVE_PATH/Products/Applications/KeyboardClean.app/Contents/Resources"
DERIVED_DATA_DIR="$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 1 -type d -name 'KeyboardClean-*' | head -n 1)"
ASSET_OUTPUT_DIR=""

TEAM_ID="${TEAM_ID:-37A43S5GYQ}"
BUNDLE_ID="${BUNDLE_ID:-com.jihyunchoi.keyboardclean}"

mkdir -p "$ROOT_DIR/build"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

sed \
  -e "s/__TEAM_ID__/$TEAM_ID/g" \
  -e "s/__BUNDLE_ID__/$BUNDLE_ID/g" \
  "$EXPORT_TEMPLATE" > "$EXPORT_PLIST"

echo "==> Archiving..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

if [[ -n "$DERIVED_DATA_DIR" ]]; then
  ASSET_OUTPUT_DIR="$DERIVED_DATA_DIR/Build/Intermediates.noindex/ArchiveIntermediates/$SCHEME/IntermediateBuildFilesPath/$SCHEME.build/Release/$SCHEME.build/assetcatalog_output/thinned"
fi

if [[ -d "$ASSET_OUTPUT_DIR" ]]; then
  mkdir -p "$ARCHIVE_APP_RESOURCES"
  if [[ -f "$ASSET_OUTPUT_DIR/AppIcon.icns" ]]; then
    cp "$ASSET_OUTPUT_DIR/AppIcon.icns" "$ARCHIVE_APP_RESOURCES/AppIcon.icns"
  fi
  if [[ -f "$ASSET_OUTPUT_DIR/Assets.car" ]]; then
    cp "$ASSET_OUTPUT_DIR/Assets.car" "$ARCHIVE_APP_RESOURCES/Assets.car"
  fi
fi

echo "==> Exporting for App Store Connect upload..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates

echo ""
echo "Done."
echo "Archive: $ARCHIVE_PATH"
echo "Export:  $EXPORT_PATH"
