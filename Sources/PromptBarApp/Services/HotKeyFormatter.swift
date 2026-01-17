import Carbon
import Foundation

enum HotKeyFormatter {
    static func string(from hotKey: HotKey) -> String {
        var parts: [String] = []

        if hotKey.modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        if hotKey.modifiers & UInt32(optionKey) != 0 { parts.append("Opt") }
        if hotKey.modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if hotKey.modifiers & UInt32(controlKey) != 0 { parts.append("Ctrl") }

        let key = keyString(for: hotKey.keyCode)
        parts.append(key)

        return parts.joined(separator: "+")
    }

    private static func keyString(for keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Escape): return "Escape"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_LeftArrow): return "Left"
        case UInt32(kVK_RightArrow): return "Right"
        case UInt32(kVK_DownArrow): return "Down"
        case UInt32(kVK_UpArrow): return "Up"
        default: return "Key \(keyCode)"
        }
    }
}
