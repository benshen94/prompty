import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = PromptStore()
    let settings = SettingsStore()

    private let hotKeyManager = HotKeyManager()
    private var statusItem: NSStatusItem!
    private var mainWindow: NSWindow!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupMainWindow()
        configureHotKey()
        bindSettings()

        showWindowOnFirstLaunch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let image = loadMenuBarIcon() {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else {
                let fallback = NSImage(systemSymbolName: "rectangle.inset.filled.and.cursorarrow", accessibilityDescription: "Prompty")
                fallback?.isTemplate = true
                fallback?.size = NSSize(width: 18, height: 18)
                button.image = fallback
            }
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupMainWindow() {
        let contentView = ContentView()
            .environmentObject(store)
            .environmentObject(settings)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        window.minSize = NSSize(width: 680, height: 420)
        window.tabbingMode = .disallowed
        window.delegate = self
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.alphaValue = settings.windowOpacity
        window.contentView = NSHostingView(rootView: contentView)

        mainWindow = window
    }

    private func showWindowOnFirstLaunch() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedPrompty") {
            defaults.set(true, forKey: "hasLaunchedPrompty")
        }
        showMainWindow()
    }

    private func configureHotKey() {
        hotKeyManager.onHotKey = { [weak self] in
            self?.showMainWindow()
        }
        hotKeyManager.register(hotKey: settings.resolvedHotKey())
    }

    private func bindSettings() {
        settings.$hotKeyMode
            .combineLatest(settings.$hotKeyPreset, settings.$customHotKey)
            .sink { [weak self] _, _, _ in
                guard let self = self else { return }
                self.hotKeyManager.register(hotKey: self.settings.resolvedHotKey())
            }
            .store(in: &cancellables)

        settings.$appearance
            .sink { [weak self] appearance in
                self?.applyAppearance(appearance)
            }
            .store(in: &cancellables)

        settings.$windowOpacity
            .sink { [weak self] opacity in
                self?.mainWindow?.alphaValue = opacity
            }
            .store(in: &cancellables)

        applyAppearance(settings.appearance)
    }

    private func applyAppearance(_ appearance: AppearanceMode) {
        switch appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showStatusMenu()
        } else {
            toggleMainWindow()
        }
    }

    @objc private func showMainWindowFromMenu() {
        showMainWindow()
    }


    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func toggleMainWindow() {
        if mainWindow.isVisible {
            mainWindow.orderOut(nil)
        } else {
            showMainWindow()
        }
    }
    

    private func showStatusMenu() {
        statusItem.menu = statusMenu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    private func loadMenuBarIcon() -> NSImage? {
        if let image = NSImage(named: NSImage.Name("MenuBarIcon")) {
            return image
        }
        if let image = loadMenuBarIconPNG(from: Bundle.module) {
            return image
        }
        if let image = loadMenuBarIconPNG(from: Bundle.main) {
            return image
        }
        guard let resourcesURL = Bundle.main.resourceURL else { return nil }
        if let urls = try? FileManager.default.contentsOfDirectory(at: resourcesURL, includingPropertiesForKeys: nil) {
            for url in urls where url.pathExtension == "bundle" {
                if let bundle = Bundle(url: url),
                   let image = loadMenuBarIconPNG(from: bundle) {
                    return image
                }
            }
        }
        return nil
    }

    private func loadMenuBarIconPNG(from bundle: Bundle) -> NSImage? {
        guard let url = bundle.url(forResource: "MenuBarIcon", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .focusSearchField, object: nil)
    }

    private var statusMenu: NSMenu {
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open Prompty", action: #selector(showMainWindowFromMenu), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        let quitItem = NSMenuItem(title: "Quit Prompty", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }
}
