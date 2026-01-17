import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

enum HotKeyMode: String, CaseIterable, Identifiable, Codable {
    case preset
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preset:
            return "Preset"
        case .custom:
            return "Custom"
        }
    }
}

enum FontStyle: String, CaseIterable, Identifiable, Codable {
    case system
    case avenirNext
    case menlo
    case georgia

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .avenirNext:
            return "Avenir Next"
        case .menlo:
            return "Menlo"
        case .georgia:
            return "Georgia"
        }
    }

    func fontName(for weight: Font.Weight) -> String? {
        switch self {
        case .system:
            return nil
        case .avenirNext:
            if weight == .bold || weight == .semibold {
                return "AvenirNext-DemiBold"
            }
            return "AvenirNext-Regular"
        case .menlo:
            if weight == .bold || weight == .semibold {
                return "Menlo-Bold"
            }
            return "Menlo-Regular"
        case .georgia:
            if weight == .bold || weight == .semibold {
                return "Georgia-Bold"
            }
            return "Georgia"
        }
    }
}

enum FontToken {
    case title
    case subtitle
    case body
    case small
    case badge

    var sizeOffset: Double {
        switch self {
        case .title:
            return 4
        case .subtitle:
            return 1
        case .body:
            return 0
        case .small:
            return -1
        case .badge:
            return -2
        }
    }
}

final class SettingsStore: ObservableObject {
    private var isReady = false

    @Published var hotKeyMode: HotKeyMode {
        didSet { saveIfReady() }
    }

    @Published var hotKeyPreset: HotKeyPreset {
        didSet { saveIfReady() }
    }

    @Published var appearance: AppearanceMode {
        didSet { saveIfReady() }
    }

    @Published var windowOpacity: Double {
        didSet { saveIfReady() }
    }

    @Published var fontStyle: FontStyle {
        didSet { saveIfReady() }
    }

    @Published var fontSize: Double {
        didSet { saveIfReady() }
    }

    @Published var customHotKey: HotKey {
        didSet { saveIfReady() }
    }

    private let defaults = UserDefaults.standard

    init() {
        let hotKeyModeRaw = defaults.string(forKey: "hotKeyMode") ?? HotKeyMode.preset.rawValue
        hotKeyMode = HotKeyMode(rawValue: hotKeyModeRaw) ?? .preset

        let presetRaw = defaults.string(forKey: "hotKeyPreset") ?? HotKeyPreset.commandShiftSpace.rawValue
        let preset = HotKeyPreset(rawValue: presetRaw) ?? .commandShiftSpace
        hotKeyPreset = preset

        let appearanceRaw = defaults.string(forKey: "appearance") ?? AppearanceMode.system.rawValue
        appearance = AppearanceMode(rawValue: appearanceRaw) ?? .system

        let opacity = defaults.object(forKey: "windowOpacity") as? Double ?? 0.92
        windowOpacity = min(max(opacity, 0.6), 1.0)

        let fontStyleRaw = defaults.string(forKey: "fontStyle") ?? FontStyle.system.rawValue
        fontStyle = FontStyle(rawValue: fontStyleRaw) ?? .system

        let size = defaults.object(forKey: "fontSize") as? Double ?? 13
        fontSize = min(max(size, 11), 20)

        let customKeyCode = defaults.object(forKey: "customHotKeyCode") as? UInt32 ?? preset.hotKey.keyCode
        let customModifiers = defaults.object(forKey: "customHotKeyModifiers") as? UInt32 ?? preset.hotKey.modifiers
        customHotKey = HotKey(keyCode: customKeyCode, modifiers: customModifiers)

        isReady = true
    } 
    
    func resolvedHotKey() -> HotKey {
        switch hotKeyMode {
        case .preset:
            return hotKeyPreset.hotKey
        case .custom:
            return customHotKey
        }
    }

    func font(_ token: FontToken, weight: Font.Weight = .regular) -> Font {
        let size = min(max(fontSize + token.sizeOffset, 10), 24)
        if let name = fontStyle.fontName(for: weight) {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }

    private func saveIfReady() {
        guard isReady else { return }
        defaults.set(hotKeyMode.rawValue, forKey: "hotKeyMode")
        defaults.set(hotKeyPreset.rawValue, forKey: "hotKeyPreset")
        defaults.set(appearance.rawValue, forKey: "appearance")
        defaults.set(windowOpacity, forKey: "windowOpacity")
        defaults.set(fontStyle.rawValue, forKey: "fontStyle")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(customHotKey.keyCode, forKey: "customHotKeyCode")
        defaults.set(customHotKey.modifiers, forKey: "customHotKeyModifiers")
    }
}
