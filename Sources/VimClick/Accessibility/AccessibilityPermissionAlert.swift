import AppKit

@MainActor
struct AccessibilityPermissionAlert {
    func presentMissingPermission() -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "VimClick needs Accessibility access to perform the mouse click you request. Enable VimClick in System Settings → Privacy & Security → Accessibility. If VimClick is already enabled but this message continues, remove the old entry with the minus button, reopen this copy, and grant access again."
        alert.addButton(withTitle: "Not Now")
        alert.addButton(withTitle: "Open System Settings")

        return alert.runModal() == .alertSecondButtonReturn
    }

    func presentClickFailure() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "VimClick Could Not Click"
        alert.informativeText = "The mouse event could not be created. Please try again."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
