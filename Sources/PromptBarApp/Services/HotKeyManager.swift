import AppKit
import Carbon
import Foundation

struct HotKey: Equatable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32
}

enum HotKeyPreset: String, CaseIterable, Identifiable, Codable {
    case commandShiftSpace
    case commandOptionP
    case commandShiftP
    case commandOptionSpace

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .commandShiftSpace:
            return "Command + Shift + Space"
        case .commandOptionP:
            return "Command + Option + P"
        case .commandShiftP:
            return "Command + Shift + P"
        case .commandOptionSpace:
            return "Command + Option + Space"
        }
    }

    var hotKey: HotKey {
        switch self {
        case .commandShiftSpace:
            return HotKey(keyCode: 49, modifiers: UInt32(cmdKey | shiftKey))
        case .commandOptionP:
            return HotKey(keyCode: 35, modifiers: UInt32(cmdKey | optionKey))
        case .commandShiftP:
            return HotKey(keyCode: 35, modifiers: UInt32(cmdKey | shiftKey))
        case .commandOptionSpace:
            return HotKey(keyCode: 49, modifiers: UInt32(cmdKey | optionKey))
        }
    }
}

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var eventHandlerUPP: EventHandlerUPP?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var fallbackHotKey: HotKey?
    private var lastHandledTimestamp: TimeInterval?

    var onHotKey: (() -> Void)?

    func register(hotKey: HotKey) {
        unregister()

        let signature = fourCharCode("PRMB")
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let eventTarget = GetApplicationEventTarget()

        let status = RegisterEventHotKey(hotKey.keyCode, hotKey.modifiers, hotKeyID, eventTarget, 0, &hotKeyRef)
        if status != noErr {
            print("Failed to register hotkey: \(status). Falling back to event monitor.")
            setupFallback(for: hotKey)
            return
        }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, _, userData in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onHotKey?()
            return noErr
        }

        eventHandlerUPP = handler
        InstallEventHandler(eventTarget, handler, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        eventHandlerUPP = nil

        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        fallbackHotKey = nil
    }

    private func setupFallback(for hotKey: HotKey) {
        fallbackHotKey = hotKey
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleFallback(event: event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleFallback(event: event)
            return event
        }
    }

    private func handleFallback(event: NSEvent) {
        guard let hotKey = fallbackHotKey else { return }
        guard event.type == .keyDown else { return }
        let modifiers = carbonModifiers(from: event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        guard modifiers == hotKey.modifiers else { return }
        guard UInt32(event.keyCode) == hotKey.keyCode else { return }
        if let lastTimestamp = lastHandledTimestamp,
           abs(event.timestamp - lastTimestamp) < 0.05 {
            return
        }
        lastHandledTimestamp = event.timestamp
        onHotKey?()
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        return modifiers
    }

    private func fourCharCode(_ string: String) -> OSType {
        var result: UInt32 = 0
        for scalar in string.unicodeScalars {
            result = (result << 8) + scalar.value
        }
        return result
    }
}
