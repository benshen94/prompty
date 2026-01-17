# Prompty

Prompty is a macOS menu bar app built with SwiftUI.

## Requirements
- macOS 13+
- Xcode 15+ (Swift 5.9)
- Python 3 with Pillow (used by the packaging script for the app icon)

## Install
1. Open `Package.swift` in Xcode and build `Prompty` (Product > Build).
2. Run:
   ```bash
   ./scripts/install_app.sh
   ```

## Build/Run From Source
```bash
swift run
```

## Package Only
```bash
./scripts/package_app.sh
```

Note: the packaging script picks the most recent Xcode build from DerivedData.
