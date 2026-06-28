import AppKit
import CoreGraphics

protocol AccessibilityPermissionProviding {
    var isTrusted: Bool { get }
    func requestSystemPrompt()
    func openSystemSettings()
}

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

extension AccessibilityPermissionService: AccessibilityPermissionProviding {}
