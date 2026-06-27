import Testing
@testable import VimClick

struct CursorControlInputTests {
    @Test func movementModeCapturesPlainVimKeys() {
        #expect(
            CursorControlInput(
                keyCode: KeyboardShortcuts.moveRightKeyCode,
                modifiers: [],
                isKeyDown: true,
                captureMode: .movement
            ) == .movementKeyDown(.right)
        )
    }

    @Test func movementModeUsesCustomMovementBindings() {
        let bindings = CursorMovementBindings(
            left: KeyboardShortcut(
                keyCode: 0,
                modifiers: [.shift],
                keyEquivalent: "a",
                displayKey: "A"
            ),
            down: CursorMovementBindings().down,
            up: CursorMovementBindings().up,
            right: CursorMovementBindings().right
        )

        #expect(
            CursorControlInput(
                keyCode: 0,
                modifiers: [.shift],
                isKeyDown: true,
                captureMode: .movement,
                movementBindings: bindings
            ) == .movementKeyDown(.left)
        )
        #expect(
            CursorControlInput(
                keyCode: KeyboardShortcuts.moveLeftKeyCode,
                modifiers: [],
                isKeyDown: true,
                captureMode: .movement,
                movementBindings: bindings
            ) == nil
        )
    }

    @Test func escapeDoesNotExitCursorControlMovementMode() {
        #expect(
            CursorControlInput(
                keyCode: UInt32(KeyboardShortcuts.escapeKeyCode),
                modifiers: [],
                isKeyDown: true,
                captureMode: .movement
            ) == nil
        )
    }

    @Test func returnClicksInMovementMode() {
        #expect(
            CursorControlInput(
                keyCode: UInt32(KeyboardShortcuts.returnKeyCodes.first!),
                modifiers: [],
                isKeyDown: true,
                captureMode: .movement
            ) == .leftClick
        )
        #expect(
            CursorControlInput(
                keyCode: UInt32(KeyboardShortcuts.returnKeyCodes.first!),
                modifiers: [.shift],
                isKeyDown: true,
                captureMode: .movement
            ) == .rightClick
        )
        #expect(
            CursorControlInput(
                keyCode: UInt32(KeyboardShortcuts.returnKeyCodes.first!),
                modifiers: [.control],
                isKeyDown: true,
                captureMode: .movement
            ) == .rightClick
        )
    }

    @Test func unsupportedModifiedReturnIsIgnored() {
        #expect(
            CursorControlInput(
                keyCode: UInt32(KeyboardShortcuts.returnKeyCodes.first!),
                modifiers: [.option],
                isKeyDown: true,
                captureMode: .movement
            ) == nil
        )
    }
}
