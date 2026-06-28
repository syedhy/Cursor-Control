enum CursorMovementDirection: CaseIterable, Hashable {
    case left
    case down
    case up
    case right
}

enum CursorControlInput: Equatable {
    case movementKeyDown(CursorMovementDirection)
    case movementKeyUp(CursorMovementDirection)
    case dragHoldChanged(Bool)
    case leftClick
    case rightClick

    init?(
        keyCode: UInt32,
        modifiers: ShortcutModifiers,
        isKeyDown: Bool,
        captureMode: CursorControlCaptureMode,
        movementBindings: CursorMovementBindings = CursorMovementBindings()
    ) {
        if keyCode == UInt32(KeyboardShortcuts.escapeKeyCode) {
            return nil
        }

        guard captureMode == .movement else { return nil }

        if KeyboardShortcuts.returnKeyCodes.contains(UInt16(keyCode)) {
            guard isKeyDown else { return nil }

            if modifiers.isEmpty {
                self = .leftClick
                return
            }

            if modifiers == [.shift] || modifiers == [.control] {
                self = .rightClick
                return
            }

            return nil
        }

        let direction = movementBindings.direction(for: keyCode, modifiers: modifiers)
            ?? movementBindings.direction(
                for: keyCode,
                modifiers: modifiers.subtracting(AppConstants.cursorDragModifier)
            )
        guard let direction else { return nil }

        self = isKeyDown ? .movementKeyDown(direction) : .movementKeyUp(direction)
    }
}

enum CursorControlCaptureMode: Equatable {
    case movement
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
