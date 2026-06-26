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
}
