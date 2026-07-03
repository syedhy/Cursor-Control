#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Cursor Control"
BUNDLE_ID="io.github.cursorcontrol.CursorControl"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
VERSION="${VERSION:-1.0.0}"
PACKAGE_NAME="${PACKAGE_NAME:-CursorControl-$VERSION-macOS}"
ZIP_PATH="${ZIP_PATH:-$DIST_DIR/$PACKAGE_NAME.zip}"
SHA_PATH="$ZIP_PATH.sha256"
APP_PATH="$DIST_DIR/$PACKAGE_NAME/$APP_NAME.app"
STRICT_GATEKEEPER="${STRICT_GATEKEEPER:-0}"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Missing release zip: $ZIP_PATH" >&2
  exit 1
fi

if [[ ! -f "$SHA_PATH" ]]; then
  echo "Missing checksum file: $SHA_PATH" >&2
  exit 1
fi

echo "Checking checksum..."
EXPECTED_SHA="$(awk '{print $1}' "$SHA_PATH")"
ACTUAL_SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

if [[ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]]; then
  echo "Checksum mismatch." >&2
  echo "Expected: $EXPECTED_SHA" >&2
  echo "Actual:   $ACTUAL_SHA" >&2
  exit 1
fi

echo "Checking zip layout..."
zipinfo -1 "$ZIP_PATH" | grep -q "^$PACKAGE_NAME/$APP_NAME.app/Contents/Info.plist$"

if zipinfo -1 "$ZIP_PATH" | grep -Eq '(^|/)__MACOSX/|(^|/)\.DS_Store$'; then
  echo "Release zip contains macOS metadata files." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expanded app not found at: $APP_PATH" >&2
  echo "Run script/package_release.sh first, or unzip the package into dist/." >&2
  exit 1
fi

echo "Checking bundle metadata..."
ACTUAL_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")"
ACTUAL_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"

if [[ "$ACTUAL_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
  echo "Unexpected bundle identifier: $ACTUAL_BUNDLE_ID" >&2
  exit 1
fi

if [[ "$ACTUAL_VERSION" != "$VERSION" ]]; then
  echo "Unexpected bundle version: $ACTUAL_VERSION" >&2
  exit 1
fi

echo "Checking code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Checking Gatekeeper assessment..."
if spctl -a -vv -t install "$APP_PATH"; then
  echo "Gatekeeper accepted the app."
else
  echo "Gatekeeper rejected the app, which is expected for an ad-hoc signed, non-notarized release."
  echo "Users must open it through System Settings > Privacy & Security > Open Anyway or Control-click > Open."
  if [[ "$STRICT_GATEKEEPER" == "1" ]]; then
    exit 1
  fi
fi

echo "Release package checks passed."
