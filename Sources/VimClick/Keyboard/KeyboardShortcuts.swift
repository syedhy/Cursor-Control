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
    static let activationKeyCode: UInt32 = 49
    static let activationModifiers: NSEvent.ModifierFlags = [.command, .shift]
    static let activationKeyEquivalent = " "
    static let activationDisplayName = "Command-Shift-Space"
    static let cancelKeyCode: UInt16 = 53
    static let zoomKeyCode: UInt16 = 49
    static let clickKeyCodes: Set<UInt16> = [36, 76]
    static let moveLeftCharacter: Character = "h"
    static let moveDownCharacter: Character = "j"
    static let moveUpCharacter: Character = "k"
    static let moveRightCharacter: Character = "l"

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
