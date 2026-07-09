#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-LingoPeek}"
PRODUCT_NAME="${PRODUCT_NAME:-LingoPeek}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.lingopeek.LingoPeek}"
APP_VERSION="${APP_VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
CONFIGURATION="${CONFIGURATION:-release}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
CODESIGN_TIMESTAMP="${CODESIGN_TIMESTAMP:-none}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://github.com/esr2587758/lingopeek/releases/latest/download/appcast.xml}"
SPARKLE_ENABLE_AUTOMATIC_CHECKS="${SPARKLE_ENABLE_AUTOMATIC_CHECKS:-true}"
SPARKLE_AUTOMATICALLY_UPDATE="${SPARKLE_AUTOMATICALLY_UPDATE:-false}"
SPARKLE_FRAMEWORK_PATH="${SPARKLE_FRAMEWORK_PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"

plist_bool() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) echo "true" ;;
    *) echo "false" ;;
  esac
}

find_sparkle_framework() {
  if [[ -n "$SPARKLE_FRAMEWORK_PATH" ]]; then
    echo "$SPARKLE_FRAMEWORK_PATH"
    return
  fi

  local found=""
  found="$(find "$REPO_ROOT/.build/artifacts" -path "*/Sparkle.xcframework/macos*/Sparkle.framework" -type d -print -quit 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    echo "$found"
    return
  fi

  found="$(find "$REPO_ROOT/.build/artifacts" -path "*/Sparkle.framework" -type d -print -quit 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    echo "$found"
  fi
}

cd "$REPO_ROOT"

echo "Building $PRODUCT_NAME ($CONFIGURATION)..."
swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$PRODUCT_NAME"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Expected executable not found: $EXECUTABLE_PATH" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod 755 "$MACOS_DIR/$APP_NAME"

SPARKLE_FRAMEWORK_SOURCE="$(find_sparkle_framework)"
if [[ -z "$SPARKLE_FRAMEWORK_SOURCE" || ! -d "$SPARKLE_FRAMEWORK_SOURCE" ]]; then
  echo "Expected Sparkle.framework not found. Run 'swift package resolve' or set SPARKLE_FRAMEWORK_PATH." >&2
  exit 1
fi

echo "Embedding Sparkle.framework..."
ditto "$SPARKLE_FRAMEWORK_SOURCE" "$FRAMEWORKS_DIR/Sparkle.framework"

cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_IDENTIFIER</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -n "$SPARKLE_PUBLIC_ED_KEY" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $SPARKLE_FEED_URL" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_ED_KEY" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUEnableAutomaticChecks bool $(plist_bool "$SPARKLE_ENABLE_AUTOMATIC_CHECKS")" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUAutomaticallyUpdate bool $(plist_bool "$SPARKLE_AUTOMATICALLY_UPDATE")" "$INFO_PLIST"
else
  echo "Sparkle update checks disabled for this package: SPARKLE_PUBLIC_ED_KEY is empty."
fi

plutil -lint "$INFO_PLIST"

echo "Signing $APP_BUNDLE..."
codesign_args=(--force --deep --sign "$SIGN_IDENTITY")
if [[ -n "$CODESIGN_TIMESTAMP" ]]; then
  codesign_args+=(--timestamp="$CODESIGN_TIMESTAMP")
fi
codesign "${codesign_args[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "Creating $ZIP_PATH..."
xattr -cr "$APP_BUNDLE" 2>/dev/null || true
COPYFILE_DISABLE=1 ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Packaged app:"
echo "  $APP_BUNDLE"
echo "  $ZIP_PATH"
