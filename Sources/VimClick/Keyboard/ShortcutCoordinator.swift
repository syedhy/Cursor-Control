import AppKit
import OSLog

enum ShortcutUpdateResult: Equatable {
    case success
    case validationFailure(String)
    case registrationFailure(String)
}

@MainActor
final class ShortcutCoordinator {
    private let store: ShortcutStore
    private let service: GlobalShortcutService
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "ShortcutCoordinator"
    )
    private var handlers: [ShortcutIdentifier: @MainActor () -> Void] = [:]

    init(
        store: ShortcutStore = ShortcutStore(),
        service: GlobalShortcutService = GlobalShortcutService()
    ) {
        self.store = store
        self.service = service
    }

    func start(handlers: [ShortcutIdentifier: @MainActor () -> Void]) -> ShortcutUpdateResult {
        self.handlers = handlers
        return applyCurrentAssignments()
    }

    func shortcut(for identifier: ShortcutIdentifier) -> KeyboardShortcut {
        store.shortcut(for: identifier)
    }

    func updateShortcut(
        _ identifier: ShortcutIdentifier,
        to shortcut: KeyboardShortcut
    ) -> ShortcutUpdateResult {
        let previousAssignments = store.load()

        switch store.update(identifier, to: shortcut) {
        case .success:
            let result = applyCurrentAssignments()
            if case .success = result {
                return .success
            }

            store.replace(with: previousAssignments)
            _ = applyCurrentAssignments()
            return result
        case .failure(let error):
            return .validationFailure(error.localizedDescription)
        }
    }

    func restoreDefaults() -> ShortcutUpdateResult {
        let previousAssignments = store.load()
        _ = store.restoreDefaults()

        let result = applyCurrentAssignments()
        if case .success = result {
            return .success
        }

        store.replace(with: previousAssignments)
        _ = applyCurrentAssignments()
        return result
    }

    func suspendRegistrations() {
        service.unregisterAll()
    }

    @discardableResult
    func resumeRegistrations() -> ShortcutUpdateResult {
        applyCurrentAssignments()
    }

    func unregisterAll() {
        service.unregisterAll()
    }

    private func applyCurrentAssignments() -> ShortcutUpdateResult {
        let result = service.registerShortcuts(store.load().all) { [weak self] identifier in
            self?.handleShortcut(identifier)
        }

        switch result {
        case .success:
            return .success
        case .failure(let failure):
            logger.error("\(failure.message)")
            return .registrationFailure(failure.message)
        }
    }

    private func handleShortcut(_ identifier: ShortcutIdentifier) {
        handlers[identifier]?()
    }
}
