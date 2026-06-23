import AppKit

@MainActor
final class ClickCoordinator {
    private let permissionService: AccessibilityPermissionService
    private let permissionAlert: AccessibilityPermissionAlert
    private let coordinateConverter: ScreenCoordinateConverter
    private let mouseClickService: MouseClickService

    init(
        permissionService: AccessibilityPermissionService = AccessibilityPermissionService(),
        permissionAlert: AccessibilityPermissionAlert = AccessibilityPermissionAlert(),
        coordinateConverter: ScreenCoordinateConverter = ScreenCoordinateConverter(),
        mouseClickService: MouseClickService = MouseClickService()
    ) {
        self.permissionService = permissionService
        self.permissionAlert = permissionAlert
        self.coordinateConverter = coordinateConverter
        self.mouseClickService = mouseClickService
    }

    func performLeftClick(at target: ClickTarget) {
        DispatchQueue.main.async { [weak self] in
            self?.executeLeftClick(at: target)
        }
    }

    private func executeLeftClick(at target: ClickTarget) {
        guard permissionService.isTrusted else {
            if permissionAlert.presentMissingPermission() {
                permissionService.requestSystemPrompt()
                permissionService.openSystemSettings()
            }
            return
        }

        guard let quartzPoint = coordinateConverter.quartzPoint(from: target),
              mouseClickService.leftClick(at: quartzPoint) else {
            permissionAlert.presentClickFailure()
            return
        }
    }
}
