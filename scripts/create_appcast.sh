#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-LingoPeek}"
APP_VERSION="${APP_VERSION:-0.1.0}"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:?Set DOWNLOAD_URL_PREFIX to the GitHub Release download URL prefix.}"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX%/}/"
PRODUCT_LINK="${PRODUCT_LINK:-https://github.com/esr2587758/lingopeek}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-}"
SPARKLE_PRIVATE_ED_KEY="${SPARKLE_PRIVATE_ED_KEY:-}"
SPARKLE_GENERATE_APPCAST="${SPARKLE_GENERATE_APPCAST:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"
ZIP_PATH="${ZIP_PATH:-$DIST_DIR/$APP_NAME.zip}"
APPCAST_WORK_DIR="${APPCAST_WORK_DIR:-$DIST_DIR/appcast-work}"
APPCAST_OUTPUT="${APPCAST_OUTPUT:-$DIST_DIR/appcast.xml}"

find_generate_appcast() {
  if [[ -n "$SPARKLE_GENERATE_APPCAST" ]]; then
    echo "$SPARKLE_GENERATE_APPCAST"
    return
  fi
  find "$REPO_ROOT/.build/artifacts" -path "*/Sparkle/bin/generate_appcast" -type f -print -quit 2>/dev/null || true
}

GENERATE_APPCAST="$(find_generate_appcast)"
if [[ -z "$GENERATE_APPCAST" || ! -x "$GENERATE_APPCAST" ]]; then
  echo "Expected Sparkle generate_appcast tool not found. Run 'swift package resolve' or set SPARKLE_GENERATE_APPCAST." >&2
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Expected update archive not found: $ZIP_PATH" >&2
  exit 1
fi

rm -rf "$APPCAST_WORK_DIR"
mkdir -p "$APPCAST_WORK_DIR" "$(dirname "$APPCAST_OUTPUT")"

cp "$ZIP_PATH" "$APPCAST_WORK_DIR/$APP_NAME.zip"
if [[ -n "$RELEASE_NOTES_FILE" && -f "$RELEASE_NOTES_FILE" ]]; then
  cp "$RELEASE_NOTES_FILE" "$APPCAST_WORK_DIR/$APP_NAME.md"
else
  {
    echo "# $APP_NAME $APP_VERSION"
    echo
    echo "See the GitHub Release for details."
  } > "$APPCAST_WORK_DIR/$APP_NAME.md"
fi

APPCAST_NAME="$(basename "$APPCAST_OUTPUT")"
APPCAST_TEMP_OUTPUT="$APPCAST_WORK_DIR/$APPCAST_NAME"
APPCAST_ARGS=(
  --download-url-prefix "$DOWNLOAD_URL_PREFIX"
  --link "$PRODUCT_LINK"
  --embed-release-notes
  -o "$APPCAST_TEMP_OUTPUT"
  "$APPCAST_WORK_DIR"
)

echo "Generating $APPCAST_OUTPUT..."
if [[ -n "$SPARKLE_PRIVATE_ED_KEY" ]]; then
  printf '%s' "$SPARKLE_PRIVATE_ED_KEY" | "$GENERATE_APPCAST" --ed-key-file - "${APPCAST_ARGS[@]}"
else
  "$GENERATE_APPCAST" "${APPCAST_ARGS[@]}"
fi

if [[ -n "$SPARKLE_PRIVATE_ED_KEY" ]] && ! grep -q 'sparkle:edSignature=' "$APPCAST_TEMP_OUTPUT"; then
  echo "Generated appcast is missing sparkle:edSignature. Check that SPARKLE_PRIVATE_ED_KEY matches the app's SPARKLE_PUBLIC_ED_KEY." >&2
  exit 1
fi

cp "$APPCAST_TEMP_OUTPUT" "$APPCAST_OUTPUT"

echo "Generated appcast:"
echo "  $APPCAST_OUTPUT"
