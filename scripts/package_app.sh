#!/bin/bash
set -euo pipefail

APP_NAME="Prompty"
BUNDLE_ID="com.prompty.app"
MIN_MACOS="13.0"
VERSION="0.1.0"
BUILD="1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Find the most recent built binary from Xcode DerivedData.
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
BIN_PATH="$(ls -t "$DERIVED_DATA"/*/Build/Products/Release/$APP_NAME "$DERIVED_DATA"/*/Build/Products/Debug/$APP_NAME 2>/dev/null | head -n 1 || true)"

if [[ -z "$BIN_PATH" ]]; then
  echo "Could not find $APP_NAME binary. Build the app in Xcode first (Product -> Build), then re-run." >&2
  exit 1
fi

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

for bundle in "$(dirname "$BIN_PATH")"/*.bundle; do
  if [[ -d "$bundle" ]]; then
    rm -rf "$RESOURCES_DIR/$(basename "$bundle")"
    cp -R "$bundle" "$RESOURCES_DIR/"
  fi
done

# Build .icns from the 1024x1024 PNG using Pillow (avoids iconutil issues).
ICON_BASE="$ROOT_DIR/Sources/PromptBarApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"

if [[ -f "$ICON_BASE" ]]; then
  python3 - <<PY
from pathlib import Path
from PIL import Image

base = Path("${ICON_BASE}")
out = Path("${RESOURCES_DIR}") / "AppIcon.icns"
img = Image.open(base)
img.save(out, sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])
print(f"Wrote {out}")
PY
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSMainNibFile</key>
  <string></string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign the bundle so LaunchServices accepts it.
codesign --force --deep --sign - "$APP_DIR"

echo "Created: $APP_DIR"
