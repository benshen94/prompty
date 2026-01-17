#!/bin/bash
set -euo pipefail

APP_NAME="Prompty"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_APP="$ROOT_DIR/dist/$APP_NAME.app"
DEST="/Applications/$APP_NAME.app"

echo "🚀 Starting Local Install for $APP_NAME..."

# Build the app using the package script
echo "📦 Packaging..."
"$ROOT_DIR/scripts/package_app.sh" > /dev/null

if [[ ! -d "$DIST_APP" ]]; then
  echo "❌ Error: Build failed. Could not find $DIST_APP" >&2
  exit 1
fi

# Stop existing instance if running
if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "🛑 Stopping currently running instance..."
  pkill -x "$APP_NAME" || true
  sleep 1
fi

echo "📂 Installing to /Applications..."
if [[ -w "/Applications" ]]; then
  rm -rf "$DEST"
  ditto "$DIST_APP" "$DEST"
  xattr -cr "$DEST" || true
else
  echo "🔑 Admin permissions required to write to /Applications"
  sudo rm -rf "$DEST"
  sudo ditto "$DIST_APP" "$DEST"
  sudo xattr -cr "$DEST" || true
fi

echo "✅ Success! $APP_NAME has been installed to $DEST"
echo "   You can launch it via Spotlight or from the Applications folder."
