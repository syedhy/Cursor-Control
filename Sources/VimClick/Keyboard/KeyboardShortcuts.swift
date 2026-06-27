import AppKit

enum KeyboardShortcuts {
    static let escapeKeyCode: UInt16 = 53
    static let returnKeyCodes: Set<UInt16> = [36, 76]
    static let moveLeftKeyCode: UInt32 = 4
    static let moveDownKeyCode: UInt32 = 38
    static let moveUpKeyCode: UInt32 = 40
    static let moveRightKeyCode: UInt32 = 37

    static let defaultGlobalShortcuts: [ShortcutIdentifier: KeyboardShortcut] = [
        .activateCursorMode: KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .shift, .option],
            keyEquivalent: "r",
            displayKey: "R"
        ),
        .scrollLeft: KeyboardShortcut(
            keyCode: moveLeftKeyCode,
            modifiers: [.command, .control, .option],
            keyEquivalent: "h",
            displayKey: "H"
        ),
        .scrollDown: KeyboardShortcut(
            keyCode: moveDownKeyCode,
            modifiers: [.command, .control, .option],
            keyEquivalent: "j",
            displayKey: "J"
        ),
        .scrollUp: KeyboardShortcut(
            keyCode: moveUpKeyCode,
            modifiers: [.command, .control, .option],
            keyEquivalent: "k",
            displayKey: "K"
        ),
        .scrollRight: KeyboardShortcut(
            keyCode: moveRightKeyCode,
            modifiers: [.command, .control, .option],
            keyEquivalent: "l",
            displayKey: "L"
        )
    ]

    static let defaultCursorMovementBindings = CursorMovementBindings(
        left: KeyboardShortcut(
            keyCode: moveLeftKeyCode,
            modifiers: [],
            keyEquivalent: "h",
            displayKey: "H"
        ),
        down: KeyboardShortcut(
            keyCode: moveDownKeyCode,
            modifiers: [],
            keyEquivalent: "j",
            displayKey: "J"
        ),
        up: KeyboardShortcut(
            keyCode: moveUpKeyCode,
            modifiers: [],
            keyEquivalent: "k",
            displayKey: "K"
        ),
        right: KeyboardShortcut(
            keyCode: moveRightKeyCode,
            modifiers: [],
            keyEquivalent: "l",
            displayKey: "L"
        )
    )
}
