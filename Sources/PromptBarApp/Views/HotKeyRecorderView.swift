import AppKit
import Carbon
import SwiftUI

struct HotKeyRecorderView: View {
    @Binding var hotKey: HotKey
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 12) {
            Text(HotKeyFormatter.string(from: hotKey))
                .font(.system(size: 12, weight: .semibold))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)

            Spacer()

            Button(isRecording ? "Press keys..." : "Record") {
                isRecording.toggle()
            }
        }
        .overlay(
            HotKeyCaptureView(isRecording: $isRecording) { newHotKey in
                hotKey = newHotKey
            }
            .frame(width: 0, height: 0)
        )
    }
}

private struct HotKeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (HotKey) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onCapture = onCapture
        view.onStop = { isRecording = false }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class KeyCaptureView: NSView {
        var isRecording = false
        var onCapture: ((HotKey) -> Void)?
        var onStop: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }

            if event.keyCode == UInt16(kVK_Escape) {
                onStop?()
                return
            }

            let modifiers = carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                NSSound.beep()
                return
            }

            let keyCode = UInt32(event.keyCode)
            onCapture?(HotKey(keyCode: keyCode, modifiers: modifiers))
            onStop?()
        }

        override func flagsChanged(with event: NSEvent) {
            if isRecording {
                // Keep focus while recording.
                window?.makeFirstResponder(self)
            }
        }

        private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
            var modifiers: UInt32 = 0
            if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
            if flags.contains(.option) { modifiers |= UInt32(optionKey) }
            if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
            if flags.contains(.control) { modifiers |= UInt32(controlKey) }
            return modifiers
        }
    }
}
