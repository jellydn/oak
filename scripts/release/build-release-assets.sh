#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-Oak}"
SCHEME="${SCHEME:-Oak}"
PROJECT_PATH="${PROJECT_PATH:-Oak/Oak.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="${VERSION:-dev}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
MARKETING_VERSION="${MARKETING_VERSION:-$VERSION}"
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-$BUILD_NUMBER}"
BUILD_ROOT="${BUILD_ROOT:-$PWD/.build/release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PWD/.build/derived-data}"

mkdir -p "$BUILD_ROOT"

ARCHIVE_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
DMG_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.dmg"
ZIP_PATH="$BUILD_ROOT/${APP_NAME}-${VERSION}.zip"
STAGING_DIR="$(mktemp -d "$BUILD_ROOT/dmg-root.XXXXXX")"
APP_ICON_PATH="$APP_PATH/Contents/Resources/AppIcon.icns"
DMG_ICON_PATH="$STAGING_DIR/.VolumeIcon.icns"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$CURRENT_PROJECT_VERSION" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Reuse the built app icon as the DMG volume icon.
if [[ -f "$APP_ICON_PATH" ]] && command -v SetFile >/dev/null; then
  cp "$APP_ICON_PATH" "$DMG_ICON_PATH"
  SetFile -a C "$STAGING_DIR"
fi

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

echo "Version metadata:"
echo "- MARKETING_VERSION=$MARKETING_VERSION"
echo "- CURRENT_PROJECT_VERSION=$CURRENT_PROJECT_VERSION"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "dmg_path=$DMG_PATH" >> "$GITHUB_OUTPUT"
  echo "zip_path=$ZIP_PATH" >> "$GITHUB_OUTPUT"
fi
