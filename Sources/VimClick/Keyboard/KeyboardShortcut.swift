import AppKit

struct KeyboardShortcut: Codable, Equatable, Hashable {
    let keyCode: UInt32
    let modifiers: ShortcutModifiers
    let keyEquivalent: String
    let displayKey: String

    init(
        keyCode: UInt32,
        modifiers: ShortcutModifiers,
        keyEquivalent: String,
        displayKey: String
    ) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyEquivalent = keyEquivalent
        self.displayKey = displayKey
    }

    init?(event: NSEvent) {
        let modifiers = ShortcutModifiers(eventModifiers: event.modifierFlags)
        guard !modifiers.intersection([.command, .control, .option]).isEmpty else {
            return nil
        }

        let keyEquivalent = KeyboardShortcut.keyEquivalent(from: event)
        guard !keyEquivalent.isEmpty else {
            return nil
        }

        self.init(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            keyEquivalent: keyEquivalent,
            displayKey: KeyboardShortcut.displayKey(
                keyCode: event.keyCode,
                keyEquivalent: keyEquivalent
            )
        )
    }

    var displayName: String {
        let prefix = modifiers.displayPrefix
        return prefix.isEmpty ? displayKey : "\(prefix)-\(displayKey)"
    }

    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        modifiers.eventModifierFlags
    }

    private static func keyEquivalent(from event: NSEvent) -> String {
        if event.keyCode == 49 {
            return " "
        }

        if event.keyCode == KeyboardShortcuts.escapeKeyCode {
            return "\u{1b}"
        }

        if KeyboardShortcuts.returnKeyCodes.contains(event.keyCode) {
            return "\r"
        }

        guard let character = event.charactersIgnoringModifiers?.lowercased(),
              character.count == 1 else {
            return ""
        }

        return character
    }

    private static func displayKey(keyCode: UInt16, keyEquivalent: String) -> String {
        switch keyCode {
        case 49:
            return "Space"
        case KeyboardShortcuts.escapeKeyCode:
            return "Escape"
        case let key where KeyboardShortcuts.returnKeyCodes.contains(key):
            return "Return"
        default:
            return keyEquivalent.uppercased()
        }
    }
}
