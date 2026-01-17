#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Prompty"
DIST_APP="$ROOT_DIR/dist/$APP_NAME.app"
DEST="/Applications/$APP_NAME.app"

"$ROOT_DIR/scripts/package_app.sh"

if [[ ! -d "$DIST_APP" ]]; then
  echo "Missing $DIST_APP. Build failed." >&2
  exit 1
fi

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "Stopping running $APP_NAME..."
  pkill -x "$APP_NAME" || true
fi

if [[ -w "/Applications" ]]; then
  ditto "$DIST_APP" "$DEST"
  xattr -cr "$DEST" || true
else
  echo "Need admin permission to install into /Applications."
  sudo ditto "$DIST_APP" "$DEST"
  sudo xattr -cr "$DEST" || true
fi

echo "Installed to $DEST"
