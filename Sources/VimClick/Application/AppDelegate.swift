import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clickCoordinator: ClickCoordinator?
    private var menuBarController: MenuBarController?
    private var overlayController: OverlayController?
    private var settingsWindowController: SettingsWindowController?
    private var shortcutCoordinator: ShortcutCoordinator?
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "AppDelegate"
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let clickCoordinator = ClickCoordinator()
        self.clickCoordinator = clickCoordinator

        let overlayController = OverlayController { [weak clickCoordinator] target in
            clickCoordinator?.performLeftClick(at: target)
        }
        self.overlayController = overlayController

        let shortcutCoordinator = ShortcutCoordinator()
        self.shortcutCoordinator = shortcutCoordinator

        let menuBarController = MenuBarController(
            activationShortcut: shortcutCoordinator.shortcut(for: .activateOverlay),
            onActivate: { [weak overlayController] in
                overlayController?.show()
            },
            onOpenSettings: { [weak self] in
                self?.settingsWindowController?.show()
            },
            onQuit: { NSApp.terminate(nil) }
        )
        self.menuBarController = menuBarController

        let settingsWindowController = SettingsWindowController(
            shortcutProvider: { [weak shortcutCoordinator] identifier in
                shortcutCoordinator?.shortcut(for: identifier)
                    ?? KeyboardShortcuts.defaultGlobalShortcuts[identifier]!
            },
            onShortcutChange: { [weak shortcutCoordinator, weak menuBarController] identifier, shortcut in
                guard let shortcutCoordinator else {
                    return .registrationFailure("Shortcut services are not available.")
                }

                let result = shortcutCoordinator.updateShortcut(identifier, to: shortcut)
                if case .success = result, identifier == .activateOverlay {
                    menuBarController?.updateActivationShortcut(shortcut)
                }
                return result
            },
            onRestoreDefaults: { [weak shortcutCoordinator, weak menuBarController] in
                guard let shortcutCoordinator else {
                    return .registrationFailure("Shortcut services are not available.")
                }

                let result = shortcutCoordinator.restoreDefaults()
                if case .success = result {
                    menuBarController?.updateActivationShortcut(
                        shortcutCoordinator.shortcut(for: .activateOverlay)
                    )
                }
                return result
            },
            onRecordingStateChanged: { [weak shortcutCoordinator] isRecording in
                if isRecording {
                    shortcutCoordinator?.suspendRegistrations()
                } else {
                    _ = shortcutCoordinator?.resumeRegistrations()
                }
            }
        )
        self.settingsWindowController = settingsWindowController

        let registrationResult = shortcutCoordinator.start(
            handlers: [
                .activateOverlay: { [weak overlayController] in
                    overlayController?.show()
                },
                .activateCursorMode: { [weak self] in
                    self?.handleReservedShortcut(.activateCursorMode)
                },
                .scrollLeft: { [weak self] in
                    self?.handleReservedShortcut(.scrollLeft)
                },
                .scrollDown: { [weak self] in
                    self?.handleReservedShortcut(.scrollDown)
                },
                .scrollUp: { [weak self] in
                    self?.handleReservedShortcut(.scrollUp)
                },
                .scrollRight: { [weak self] in
                    self?.handleReservedShortcut(.scrollRight)
                }
            ]
        )
        if case .registrationFailure(let message) = registrationResult {
            logger.error("\(message)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        clickCoordinator?.refreshAccessibilityPermission()
    }

    func applicationDidResignActive(_ notification: Notification) {
        overlayController?.handleApplicationDeactivation()
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutCoordinator?.unregisterAll()
    }

    private func handleReservedShortcut(_ identifier: ShortcutIdentifier) {
        logger.notice("Received reserved shortcut \(identifier.title)")
        NSSound.beep()
    }
}
