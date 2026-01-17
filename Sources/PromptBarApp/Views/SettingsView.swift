import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "slider.horizontal.3")
                }
            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .padding(16)
        .frame(width: 440, height: 360)
        .background(GlassBackground(material: .hudWindow, blendingMode: .behindWindow))
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Hotkey")
                    .font(.system(size: 12, weight: .semibold))
                Picker("Hotkey Mode", selection: $settings.hotKeyMode) {
                    ForEach(HotKeyMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                if settings.hotKeyMode == .preset {
                    Picker("Hotkey", selection: $settings.hotKeyPreset) {
                        ForEach(HotKeyPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                } else {
                    HotKeyRecorderView(hotKey: $settings.customHotKey)
                }

                Text("Current: \(HotKeyFormatter.string(from: settings.resolvedHotKey()))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.system(size: 12, weight: .semibold))
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Window transparency")
                    .font(.system(size: 12, weight: .semibold))
                Slider(value: $settings.windowOpacity, in: 0.6...1.0, step: 0.02)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Typography")
                    .font(.system(size: 12, weight: .semibold))
                Picker("Font style", selection: $settings.fontStyle) {
                    ForEach(FontStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                HStack {
                    Text("Font size")
                        .font(.system(size: 12))
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .font(.system(size: 12))
                }
                Slider(value: $settings.fontSize, in: 11...20, step: 1)
            }

            Spacer()
        }
        .padding(8)
    }

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                ShortcutRow(title: "Toggle Prompty", keys: HotKeyFormatter.string(from: settings.resolvedHotKey()))
                ShortcutRow(title: "New Prompt", keys: "Cmd+N")
                ShortcutRow(title: "New Folder", keys: "Cmd+Shift+N")
                ShortcutRow(title: "Edit Selected Prompt", keys: "Cmd+E")
                ShortcutRow(title: "Open Settings", keys: "Cmd+,")
                ShortcutRow(title: "Open Folder / Copy Prompt", keys: "Enter")
                ShortcutRow(title: "Back Out of Folder", keys: "Esc")
                ShortcutRow(title: "Navigate Lists", keys: "Arrow Keys")
            }

            Spacer()
        }
        .padding(8)
    }
}

private struct ShortcutRow: View {
    let title: String
    let keys: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
            Spacer()
            Text(keys)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
