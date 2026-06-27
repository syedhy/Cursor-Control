import Foundation
import Testing
@testable import VimClick

struct CursorMovementBindingStoreTests {
    @Test func loadsDefaultMovementBindings() {
        let store = makeStore()

        #expect(store.shortcut(for: .left).displayName == "H")
        #expect(store.shortcut(for: .down).displayName == "J")
        #expect(store.shortcut(for: .up).displayName == "K")
        #expect(store.shortcut(for: .right).displayName == "L")
    }

    @Test func persistsCustomMovementBindingWithoutPrimaryModifier() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 0,
            modifiers: [],
            keyEquivalent: "a",
            displayKey: "A"
        )

        let result = store.update(.left, to: shortcut)

        guard case .success = result else {
            Issue.record("Expected movement binding update to succeed")
            return
        }

        #expect(store.shortcut(for: .left) == shortcut)
    }

    @Test func persistsCustomMovementBindingWithShiftModifier() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: KeyboardShortcuts.moveLeftKeyCode,
            modifiers: [.shift],
            keyEquivalent: "h",
            displayKey: "H"
        )

        let result = store.update(.left, to: shortcut)

        guard case .success = result else {
            Issue.record("Expected movement binding update to succeed")
            return
        }

        #expect(store.shortcut(for: .left).displayName == "Shift-H")
    }

    @Test func rejectsDuplicateMovementBinding() {
        let store = makeStore()
        let duplicate = CursorMovementBindings().right

        let result = store.update(.left, to: duplicate)

        #expect(result == .failure(.duplicate(.right)))
    }

    @Test func rejectsReservedMovementKeys() {
        let store = makeStore()
        let escape = KeyboardShortcut(
            keyCode: UInt32(KeyboardShortcuts.escapeKeyCode),
            modifiers: [],
            keyEquivalent: "\u{1b}",
            displayKey: "Escape"
        )
        let enter = KeyboardShortcut(
            keyCode: UInt32(KeyboardShortcuts.returnKeyCodes.first!),
            modifiers: [],
            keyEquivalent: "\r",
            displayKey: "Return"
        )

        #expect(store.update(.left, to: escape) == .failure(.reservedKey))
        #expect(store.update(.left, to: enter) == .failure(.reservedKey))
    }

    @Test func restoreDefaultsClearsCustomMovementBinding() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 0,
            modifiers: [],
            keyEquivalent: "a",
            displayKey: "A"
        )

        _ = store.update(.left, to: shortcut)
        _ = store.restoreDefaults()

        #expect(store.shortcut(for: .left).displayName == "H")
    }

    private func makeStore() -> CursorMovementBindingStore {
        let suiteName = "VimClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return CursorMovementBindingStore(userDefaults: defaults)
    }
}
