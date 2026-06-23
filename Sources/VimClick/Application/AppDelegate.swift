import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settingsWindowController = SettingsWindowController()
        self.settingsWindowController = settingsWindowController

        menuBarController = MenuBarController(
            onActivate: { [weak self] in self?.activateVimClick() },
            onOpenSettings: { [weak settingsWindowController] in
                settingsWindowController?.show()
            },
            onQuit: { NSApp.terminate(nil) }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func activateVimClick() {
        // The overlay activation flow is implemented in Phase 2.
    }
}
