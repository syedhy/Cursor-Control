import AppKit
import Testing
@testable import VimClick

struct ShortcutStoreTests {
    @Test func loadsDefaultsWhenNothingIsPersisted() {
        let store = makeStore()

        #expect(store.shortcut(for: .activateOverlay) == KeyboardShortcuts.defaultActivationShortcut)
        #expect(store.shortcut(for: .scrollRight).displayName == "Command-Control-L")
    }

    @Test func persistsUpdatedShortcuts() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .option],
            keyEquivalent: "r",
            displayKey: "R"
        )

        let result = store.update(.activateOverlay, to: shortcut)

        guard case .success = result else {
            Issue.record("Expected shortcut update to succeed")
            return
        }

        #expect(store.shortcut(for: .activateOverlay) == shortcut)
    }

    @Test func rejectsDuplicateShortcuts() {
        let store = makeStore()
        let duplicate = KeyboardShortcuts.defaultGlobalShortcuts[.scrollLeft]!

        let result = store.update(.scrollRight, to: duplicate)

        #expect(result == .failure(.duplicate(.scrollLeft)))
    }

    @Test func rejectsShortcutsWithoutCommandControlOrOption() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.shift],
            keyEquivalent: "r",
            displayKey: "R"
        )

        let result = store.update(.activateOverlay, to: shortcut)

        #expect(result == .failure(.missingPrimaryModifier))
    }

    @Test func restoreDefaultsClearsCustomShortcut() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .option],
            keyEquivalent: "r",
            displayKey: "R"
        )

        _ = store.update(.activateOverlay, to: shortcut)
        _ = store.restoreDefaults()

        #expect(store.shortcut(for: .activateOverlay) == KeyboardShortcuts.defaultActivationShortcut)
    }

    @Test func activationShortcutCanBeChangedBackToCommandShiftSpace() {
        let store = makeStore()
        let customShortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .option],
            keyEquivalent: "r",
            displayKey: "R"
        )

        _ = store.update(.activateOverlay, to: customShortcut)
        let result = store.update(.activateOverlay, to: KeyboardShortcuts.defaultActivationShortcut)

        guard case .success = result else {
            Issue.record("Expected restoring Command-Shift-Space to succeed")
            return
        }

        #expect(store.shortcut(for: .activateOverlay) == KeyboardShortcuts.defaultActivationShortcut)
    }

    private func makeStore() -> ShortcutStore {
        let suiteName = "VimClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return ShortcutStore(userDefaults: defaults)
    }
}
