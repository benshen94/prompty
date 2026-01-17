import AppKit
import SwiftUI

@main
struct PromptyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settings)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Text("Settings...")
                    }
                } else {
                    Button("Settings...") {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                    .keyboardShortcut(",", modifiers: [.command])
                }
            }

            CommandGroup(after: .newItem) {
                Button("New Prompt") {
                    NotificationCenter.default.post(name: .showNewPrompt, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("New Folder") {
                    NotificationCenter.default.post(name: .showNewFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("Prompt") {
                Button("Edit Selected Prompt") {
                    NotificationCenter.default.post(name: .editSelectedPrompt, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])
            }
        }
    }
}
