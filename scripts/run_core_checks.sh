#!/usr/bin/env bash

set -euo pipefail

CONFIGURATION="${CONFIGURATION:-debug}"

swift build -c "$CONFIGURATION" --product LingoPeekCoreChecks

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
CHECKS_BIN="$BIN_DIR/LingoPeekCoreChecks"

if [[ ! -x "$CHECKS_BIN" ]]; then
  echo "Expected checks executable not found: $CHECKS_BIN" >&2
  exit 1
fi

if [[ "$(uname)" == "Darwin" ]]; then
  codesign --force --sign - "$CHECKS_BIN" >/dev/null 2>&1 || true
fi

"$CHECKS_BIN"
