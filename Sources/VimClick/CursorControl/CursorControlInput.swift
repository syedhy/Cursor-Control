enum CursorMovementDirection: Hashable {
    case left
    case down
    case up
    case right
}

enum CursorControlInput: Equatable {
    case movementKeyDown(CursorMovementDirection)
    case movementKeyUp(CursorMovementDirection)
    case click
    case cancel
    case resumeMovement

    init?(
        keyCode: UInt32,
        modifiers: ShortcutModifiers,
        isKeyDown: Bool,
        captureMode: CursorControlCaptureMode
    ) {
        guard modifiers.isEmpty else { return nil }

        if keyCode == UInt32(KeyboardShortcuts.escapeKeyCode) {
            guard isKeyDown else { return nil }
            self = captureMode == .textEntry ? .resumeMovement : .cancel
            return
        }

        guard captureMode == .movement else { return nil }

        if KeyboardShortcuts.returnKeyCodes.contains(UInt16(keyCode)) {
            guard isKeyDown else { return nil }
            self = .click
            return
        }

        guard let direction = CursorMovementDirection(keyCode: keyCode) else {
            return nil
        }

        self = isKeyDown ? .movementKeyDown(direction) : .movementKeyUp(direction)
    }
}

enum CursorControlCaptureMode: Equatable {
    case movement
    case textEntry
}

extension CursorMovementDirection {
    init?(keyCode: UInt32) {
        switch keyCode {
        case KeyboardShortcuts.moveLeftKeyCode:
            self = .left
        case KeyboardShortcuts.moveDownKeyCode:
            self = .down
        case KeyboardShortcuts.moveUpKeyCode:
            self = .up
        case KeyboardShortcuts.moveRightKeyCode:
            self = .right
        default:
            return nil
        }
    }
}
