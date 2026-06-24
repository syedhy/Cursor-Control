import AppKit
import CoreGraphics

struct AccessibilityPermissionService {
    var isTrusted: Bool {
        CGPreflightPostEventAccess()
    }

    func requestSystemPrompt() {
        _ = CGRequestPostEventAccess()
    }

    func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
