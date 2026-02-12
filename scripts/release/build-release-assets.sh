#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-Oak}"
SCHEME="${SCHEME:-Oak}"
PROJECT_PATH="${PROJECT_PATH:-Oak/Oak.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="${VERSION:-dev}"
BUILD_ROOT="${BUILD_ROOT:-$PWD/.build/release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PWD/.build/derived-data}"

mkdir -p "$BUILD_ROOT"

ARCHIVE_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
DMG_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.dmg"
ZIP_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.zip"
STAGING_DIR="$(mktemp -d "$BUILD_ROOT/dmg-root.XXXXXX")"

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Created release assets:"
echo "- $DMG_PATH"
echo "- $ZIP_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "dmg_path=$DMG_PATH" >> "$GITHUB_OUTPUT"
  echo "zip_path=$ZIP_PATH" >> "$GITHUB_OUTPUT"
fi
