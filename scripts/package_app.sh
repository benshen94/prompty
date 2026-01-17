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
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

echo "🧹 Cleaning up..."
rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "🔨 Building $APP_NAME..."
# Build using Swift Package Manager
swift build -c release --product "$APP_NAME"

# Locate the binary
BIN_PATH="$ROOT_DIR/.build/release/$APP_NAME"

if [[ ! -f "$BIN_PATH" ]]; then
  echo "Error: Could not find built binary at $BIN_PATH" >&2
  exit 1
fi

echo "📦 Packaging App Bundle..."
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Convert AppIcon.appiconset to .icns using native iconutil
ICONSET_SOURCE="$ROOT_DIR/Sources/PromptBarApp/Resources/Assets.xcassets/AppIcon.appiconset"
if [[ -d "$ICONSET_SOURCE" ]]; then
    TEMP_ICONSET="$(mktemp -d)/Prompty.iconset"
    cp -R "$ICONSET_SOURCE/" "$TEMP_ICONSET/"
    iconutil -c icns "$TEMP_ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$(dirname "$TEMP_ICONSET")"
    echo "   Generated AppIcon.icns"
else
    echo "   Warning: Icon source not found at $ICONSET_SOURCE"
fi

# Create Info.plist
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

# Copy any bundles/resources if they exist (adjust path as needed)
# Currently copying from adjacent to binary if SPM put them there
for bundle in "$(dirname "$BIN_PATH")"/*.bundle; do
  if [[ -d "$bundle" ]]; then
    cp -R "$bundle" "$RESOURCES_DIR/"
  fi
done

# Ad-hoc sign the bundle
echo "✍️  Signing..."
codesign --force --deep --sign - "$APP_DIR"

echo "💿 Creating DMG..."
# Create a temporary folder for DMG contents
DMG_TMP_DIR="$(mktemp -d)"
cp -R "$APP_DIR" "$DMG_TMP_DIR/"
ln -s /Applications "$DMG_TMP_DIR/Applications"

# Create the DMG
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_TMP_DIR" \
  -ov -format UDZO \
  "$DMG_PATH" \
  -quiet

# Cleanup
rm -rf "$DMG_TMP_DIR"

echo "✅ Done! DMG created at: $DMG_PATH"
