import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var cursorControlService: CursorControlService?
    private var menuBarController: MenuBarController?
    private var onboardingWindowController: OnboardingWindowController?
    private var scrollService: ScrollService?
    private var scrollSettingsStore: ScrollSettingsStore?
    private var cursorSettingsStore: CursorSettingsStore?
    private var settingsWindowController: SettingsWindowController?
    private var shortcutCoordinator: ShortcutCoordinator?
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "AppDelegate"
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let scrollSettingsStore = ScrollSettingsStore()
        self.scrollSettingsStore = scrollSettingsStore
        let scrollService = ScrollService(settingsProvider: { scrollSettingsStore.load() })
        self.scrollService = scrollService
        let cursorSettingsStore = CursorSettingsStore()
        self.cursorSettingsStore = cursorSettingsStore
        let cursorControlService = CursorControlService(
            settingsProvider: { cursorSettingsStore.load() }
        )
        self.cursorControlService = cursorControlService

        let shortcutCoordinator = ShortcutCoordinator()
        self.shortcutCoordinator = shortcutCoordinator

        let onboardingWindowController = OnboardingWindowController()
        self.onboardingWindowController = onboardingWindowController

        let menuBarController = MenuBarController(
            cursorModeShortcut: shortcutCoordinator.shortcut(for: .activateCursorMode),
            onToggleCursorMode: { [weak cursorControlService] in
                cursorControlService?.toggle()
            },
            onShowGuide: { [weak onboardingWindowController] in
                onboardingWindowController?.show()
            },
            onOpenSettings: { [weak self] in
                self?.settingsWindowController?.show()
            },
            onQuit: { NSApp.terminate(nil) }
        )
        self.menuBarController = menuBarController

        cursorControlService.onActiveStateChanged = {
            [weak menuBarController, weak shortcutCoordinator] isActive in
            shortcutCoordinator?.setCursorModeActive(isActive)
            menuBarController?.setCursorModeActive(isActive)
        }
        cursorControlService.onCaptureModeChanged = { [weak shortcutCoordinator] captureMode in
            shortcutCoordinator?.setCursorCaptureMode(captureMode)
        }

        let settingsWindowController = SettingsWindowController(
            shortcutProvider: { [weak shortcutCoordinator] identifier in
                shortcutCoordinator?.shortcut(for: identifier)
                    ?? KeyboardShortcuts.defaultGlobalShortcuts[identifier]!
            },
            scrollSettingsProvider: { [weak scrollSettingsStore] in
                scrollSettingsStore?.load() ?? ScrollSettings()
            },
            cursorSettingsProvider: { [weak cursorSettingsStore] in
                cursorSettingsStore?.load() ?? CursorSettings()
            },
            onShortcutChange: { [weak shortcutCoordinator, weak menuBarController] identifier, shortcut in
                guard let shortcutCoordinator else {
                    return .registrationFailure("Shortcut services are not available.")
                }

                let result = shortcutCoordinator.updateShortcut(identifier, to: shortcut)
                if case .success = result, identifier == .activateCursorMode {
                    menuBarController?.updateCursorModeShortcut(shortcut)
                }
                return result
            },
            onRestoreDefaults: { [weak shortcutCoordinator, weak menuBarController] in
                guard let shortcutCoordinator else {
                    return .registrationFailure("Shortcut services are not available.")
                }

                let result = shortcutCoordinator.restoreDefaults()
                if case .success = result {
                    menuBarController?.updateCursorModeShortcut(
                        shortcutCoordinator.shortcut(for: .activateCursorMode)
                    )
                }
                return result
            },
            onScrollSettingsChange: { [weak scrollSettingsStore] settings in
                scrollSettingsStore?.save(settings)
            },
            onRestoreScrollSettingsDefaults: { [weak scrollSettingsStore] in
                scrollSettingsStore?.restoreDefaults() ?? ScrollSettings()
            },
            onCursorSettingsChange: { [weak cursorSettingsStore] settings in
                cursorSettingsStore?.save(settings)
            },
            onRestoreCursorSettingsDefaults: { [weak cursorSettingsStore] in
                cursorSettingsStore?.restoreDefaults() ?? CursorSettings()
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
                .activateCursorMode: { [weak self] _ in
                    self?.cursorControlService?.toggle()
                },
                .scrollLeft: { [weak self] repeatCount in
                    self?.scroll(.left, repeatCount: repeatCount)
                },
                .scrollDown: { [weak self] repeatCount in
                    self?.scroll(.down, repeatCount: repeatCount)
                },
                .scrollUp: { [weak self] repeatCount in
                    self?.scroll(.up, repeatCount: repeatCount)
                },
                .scrollRight: { [weak self] repeatCount in
                    self?.scroll(.right, repeatCount: repeatCount)
                }
            ],
            onCursorInput: { [weak cursorControlService] input in
                cursorControlService?.handle(input)
            },
            onInputTapDisabled: { [weak cursorControlService] in
                cursorControlService?.releaseAllMovementKeys()
            }
        )
        if case .registrationFailure(let message) = registrationResult {
            logger.error("\(message)")
        }

        maybeShowOnboarding()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        scrollService?.refreshAccessibilityPermission()
        cursorControlService?.refreshAccessibilityPermission()
    }

    func applicationDidResignActive(_ notification: Notification) {
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutCoordinator?.unregisterAll()
    }

    private func scroll(_ direction: ScrollDirection, repeatCount: Int) {
        scrollService?.scroll(
            direction,
            isInteractionActive: false,
            repeatCount: repeatCount
        )
    }

    private func maybeShowOnboarding() {
        let key = "VimClick.HasShownCursorScrollOnboarding.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        UserDefaults.standard.set(true, forKey: key)
        onboardingWindowController?.show()
    }
}
