import AppKit

enum OverlayKeyboardCommand: Equatable {
    case ignore
    case cancel
    case moveLeft
    case moveDown
    case moveUp
    case moveRight
    case zoom
    case click
    case typeCharacter(Character)
}

enum OverlayKeyboardMode: Equatable {
    case coarse
    case precision
}

enum KeyboardShortcuts {
    static let spaceKeyCode: UInt16 = 49
    static let escapeKeyCode: UInt16 = 53
    static let returnKeyCodes: Set<UInt16> = [36, 76]
    static let cancelKeyCode = escapeKeyCode
    static let zoomKeyCode = spaceKeyCode
    static let clickKeyCodes = returnKeyCodes
    static let moveLeftCharacter: Character = "h"
    static let moveDownCharacter: Character = "j"
    static let moveUpCharacter: Character = "k"
    static let moveRightCharacter: Character = "l"
    static let moveLeftKeyCode: UInt32 = 4
    static let moveDownKeyCode: UInt32 = 38
    static let moveUpKeyCode: UInt32 = 40
    static let moveRightKeyCode: UInt32 = 37

    static let defaultGlobalShortcuts: [ShortcutIdentifier: KeyboardShortcut] = [
        .activateOverlay: KeyboardShortcut(
            keyCode: UInt32(spaceKeyCode),
            modifiers: [.command, .shift],
            keyEquivalent: " ",
            displayKey: "Space"
        ),
        .activateCursorMode: KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .shift, .option],
            keyEquivalent: "r",
            displayKey: "R"
        ),
        .scrollLeft: KeyboardShortcut(
            keyCode: moveLeftKeyCode,
            modifiers: [.command, .control],
            keyEquivalent: "h",
            displayKey: "H"
        ),
        .scrollDown: KeyboardShortcut(
            keyCode: moveDownKeyCode,
            modifiers: [.command, .control],
            keyEquivalent: "j",
            displayKey: "J"
        ),
        .scrollUp: KeyboardShortcut(
            keyCode: moveUpKeyCode,
            modifiers: [.command, .control],
            keyEquivalent: "k",
            displayKey: "K"
        ),
        .scrollRight: KeyboardShortcut(
            keyCode: moveRightKeyCode,
            modifiers: [.command, .control],
            keyEquivalent: "l",
            displayKey: "L"
        )
    ]

    static var defaultActivationShortcut: KeyboardShortcut {
        defaultGlobalShortcuts[.activateOverlay]!
    }

    static func command(
        for event: NSEvent,
        mode: OverlayKeyboardMode = .coarse
    ) -> OverlayKeyboardCommand? {
        if event.keyCode == cancelKeyCode {
            return .cancel
        }

        if clickKeyCodes.contains(event.keyCode) {
            return .click
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == zoomKeyCode {
            guard modifiers.intersection([.command, .control, .option]).isEmpty else {
                return nil
            }

            return mode == .coarse ? .zoom : .ignore
        }

        guard let characters = event.charactersIgnoringModifiers?.lowercased(),
              characters.count == 1,
              let character = characters.first else {
            return nil
        }

        let hasCommandOrOption = !modifiers.intersection([.command, .option]).isEmpty

        if mode == .precision {
            guard !hasCommandOrOption else { return nil }

            if modifiers.contains(.control) {
                return isMovementCharacter(character) ? .ignore : nil
            }

            switch character {
            case moveLeftCharacter:
                return .moveLeft
            case moveDownCharacter:
                return .moveDown
            case moveUpCharacter:
                return .moveUp
            case moveRightCharacter:
                return .moveRight
            default:
                // Direct identifiers are intentionally unavailable after zooming.
                return .ignore
            }
        }

        if modifiers.contains(.control), !hasCommandOrOption {
            switch character {
            case moveLeftCharacter:
                return .moveLeft
            case moveDownCharacter:
                return .moveDown
            case moveUpCharacter:
                return .moveUp
            case moveRightCharacter:
                return .moveRight
            default:
                return nil
            }
        }

        guard modifiers.intersection([.command, .control, .option]).isEmpty else {
            return nil
        }

        return .typeCharacter(character)
    }

    private static func isMovementCharacter(_ character: Character) -> Bool {
        [
            moveLeftCharacter,
            moveDownCharacter,
            moveUpCharacter,
            moveRightCharacter
        ].contains(character)
    }
}
