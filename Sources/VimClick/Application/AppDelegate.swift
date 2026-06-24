import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clickCoordinator: ClickCoordinator?
    private var menuBarController: MenuBarController?
    private var overlayController: OverlayController?
    private var settingsWindowController: SettingsWindowController?
    private var globalShortcutService: GlobalShortcutService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let clickCoordinator = ClickCoordinator()
        self.clickCoordinator = clickCoordinator

        let overlayController = OverlayController { [weak clickCoordinator] target in
            clickCoordinator?.performLeftClick(at: target)
        }
        self.overlayController = overlayController

        let settingsWindowController = SettingsWindowController()
        self.settingsWindowController = settingsWindowController

        let globalShortcutService = GlobalShortcutService()
        globalShortcutService.registerActivationShortcut { [weak overlayController] in
            overlayController?.show()
        }
        self.globalShortcutService = globalShortcutService

        menuBarController = MenuBarController(
            onActivate: { [weak overlayController] in
                overlayController?.show()
            },
            onOpenSettings: { [weak settingsWindowController] in
                settingsWindowController?.show()
            },
            onQuit: { NSApp.terminate(nil) }
        )
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
        globalShortcutService?.unregisterAll()
    }
}
