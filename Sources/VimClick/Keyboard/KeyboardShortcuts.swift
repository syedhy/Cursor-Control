import AppKit

enum OverlayKeyboardCommand: Equatable {
    case cancel
    case moveLeft
    case moveDown
    case moveUp
    case moveRight
    case typeCharacter(Character)
}

enum KeyboardShortcuts {
    static let cancelKeyCode: UInt16 = 53
    static let moveLeftCharacter: Character = "h"
    static let moveDownCharacter: Character = "j"
    static let moveUpCharacter: Character = "k"
    static let moveRightCharacter: Character = "l"

    static func command(for event: NSEvent) -> OverlayKeyboardCommand? {
        if event.keyCode == cancelKeyCode {
            return .cancel
        }

        guard let characters = event.charactersIgnoringModifiers?.lowercased(),
              characters.count == 1,
              let character = characters.first else {
            return nil
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasDisallowedMovementModifier = !modifiers.intersection([.command, .option]).isEmpty

        if modifiers.contains(.control), !hasDisallowedMovementModifier {
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
}
