# Prompty

Prompty is a minimal, powerful menu bar application for macOS.

<p align="center">
  <img src="Sources/PromptBarApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" height="128" alt="Prompty Icon">
</p>

## 📥 Installation

**For Users:**

1.  **Download** the latest `.dmg` file from the [Releases](https://github.com/benshen94/prompty/releases) page.
2.  **Open** the `Prompty.dmg` file.
3.  **Drag** the Prompty app into your **Applications** folder.
4.  Open **Prompty** from your Applications folder.

*Note: Since this app is not yet notarized by Apple, you may need to Right-Click the app and select "Open" the first time you run it.*

---

## 🛠️ Development

If you want to build the app from source or contribute.

### Requirements
- macOS 13.0 or later
- Swift 5.9+ (installed via Xcode or command line tools)

### Building & Running

**Run directly:**
```bash
swift run
```

**Create Standalone App & DMG:**
This will create `dist/Prompty.dmg` and `dist/Prompty.app`.
```bash
./scripts/package_app.sh
```

**Install Locally (Dev):**
Builds and installs directly to your `/Applications` folder.
```bash
./scripts/install_app.sh
```