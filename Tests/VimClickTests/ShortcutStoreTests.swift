import AppKit
import Foundation
import Testing
@testable import VimClick

struct ShortcutStoreTests {
    @Test func loadsDefaultsWhenNothingIsPersisted() {
        let store = makeStore()

        #expect(
            store.shortcut(for: .activateCursorMode)
                == KeyboardShortcuts.defaultGlobalShortcuts[.activateCursorMode]
        )
        #expect(store.shortcut(for: .activateCursorMode).displayName == "Option-W")
        #expect(store.shortcut(for: .scrollRight).displayName == "Control-L")
    }

    @Test func persistsUpdatedShortcuts() {
        let store = makeStore()
        let shortcut = KeyboardShortcut(
            keyCode: 15,
            modifiers: [.command, .option],
            keyEquivalent: "r",
            displayKey: "R"
        )

        let result = store.update(.activateCursorMode, to: shortcut)

        guard case .success = result else {
            Issue.record("Expected shortcut update to succeed")
            return
        }

        #expect(store.shortcut(for: .activateCursorMode) == shortcut)
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

        let result = store.update(.activateCursorMode, to: shortcut)

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

        _ = store.update(.activateCursorMode, to: shortcut)
        _ = store.restoreDefaults()

        #expect(
            store.shortcut(for: .activateCursorMode)
                == KeyboardShortcuts.defaultGlobalShortcuts[.activateCursorMode]
        )
    }

    @Test func migratesLegacyShortcutStorageWithoutRestoringRemovedOverlayShortcut() throws {
        let suiteName = "VimClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyJSON = """
        {
          "shortcuts": [
            "activateOverlay",
            {
              "keyCode": 49,
              "displayKey": "Space",
              "modifiers": 3,
              "keyEquivalent": " "
            },
            "activateCursorMode",
            {
              "keyCode": 13,
              "displayKey": "W",
              "modifiers": 4,
              "keyEquivalent": "w"
            }
          ]
        }
        """
        defaults.set(legacyJSON.data(using: .utf8)!, forKey: "VimClick.GlobalShortcuts.v3")

        let store = ShortcutStore(userDefaults: defaults)

        #expect(store.shortcut(for: .activateCursorMode).displayName == "Option-W")
        #expect(store.shortcut(for: .scrollDown).displayName == "Control-J")
    }

    private func makeStore() -> ShortcutStore {
        let suiteName = "VimClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return ShortcutStore(userDefaults: defaults)
    }
}
