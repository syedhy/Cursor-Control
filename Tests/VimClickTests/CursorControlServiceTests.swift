import CoreGraphics
import Testing
@testable import VimClick

@MainActor
struct CursorControlServiceTests {
    private let clickLocation = CGPoint(x: 300, y: 220)

    @Test func successfulClickKeepsCursorControlActive() {
        let mouseClickService = SpyMouseClickService()
        let service = makeService(mouseClickService: mouseClickService)
        var activeStateChanges: [Bool] = []
        service.onActiveStateChanged = { activeStateChanges.append($0) }

        service.start()
        service.handle(.click)

        #expect(service.isActive)
        #expect(service.captureMode == .movement)
        #expect(mouseClickService.clickedPoints == [clickLocation])
        #expect(activeStateChanges == [true])
    }

    @Test func failedClickKeepsCursorControlActive() {
        let mouseClickService = SpyMouseClickService()
        mouseClickService.shouldSucceed = false
        let alert = FakeAccessibilityAlert()
        let service = makeService(
            alert: alert,
            mouseClickService: mouseClickService
        )

        service.start()
        service.handle(.click)

        #expect(service.isActive)
        #expect(service.captureMode == .movement)
        #expect(alert.clickFailureCount == 1)
    }

    @Test func successfulMovementReportsMovedCursorPoint() {
        let cursorPositionService = FakeCursorPositionService(
            currentLocation: clickLocation,
            currentDisplayBounds: CGRect(x: 0, y: 0, width: 1200, height: 800)
        )
        let service = makeService(cursorPositionService: cursorPositionService)
        var movedPoints: [CGPoint] = []
        service.onCursorMoved = { movedPoints.append($0) }

        service.start()
        service.handle(.movementKeyDown(.right))

        #expect(movedPoints == cursorPositionService.movedPoints)
        #expect(movedPoints.count == 1)
        #expect(movedPoints.first?.x ?? 0 > clickLocation.x)
    }

    private func makeService(
        permission: FakeAccessibilityPermission = FakeAccessibilityPermission(isTrusted: true),
        alert: FakeAccessibilityAlert = FakeAccessibilityAlert(),
        cursorPositionService: FakeCursorPositionService? = nil,
        mouseClickService: SpyMouseClickService = SpyMouseClickService()
    ) -> CursorControlService {
        CursorControlService(
            permissionService: permission,
            permissionAlert: alert,
            cursorPositionService: cursorPositionService ?? FakeCursorPositionService(
                currentLocation: clickLocation,
                currentDisplayBounds: CGRect(x: 0, y: 0, width: 1200, height: 800)
            ),
            mouseClickService: mouseClickService
        )
    }
}

private final class FakeAccessibilityPermission: AccessibilityPermissionProviding {
    var isTrusted: Bool
    private(set) var requestPromptCount = 0
    private(set) var openSettingsCount = 0

    init(isTrusted: Bool) {
        self.isTrusted = isTrusted
    }

    func requestSystemPrompt() {
        requestPromptCount += 1
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}

@MainActor
private final class FakeAccessibilityAlert: AccessibilityPermissionAlerting {
    private(set) var missingPermissionCount = 0
    private(set) var clickFailureCount = 0

    func presentMissingPermission() -> Bool {
        missingPermissionCount += 1
        return false
    }

    func presentClickFailure() {
        clickFailureCount += 1
    }
}

private final class FakeCursorPositionService: CursorPositionProviding {
    var currentLocation: CGPoint?
    var currentDisplayBounds: CGRect?
    private(set) var movedPoints: [CGPoint] = []

    init(currentLocation: CGPoint?, currentDisplayBounds: CGRect?) {
        self.currentLocation = currentLocation
        self.currentDisplayBounds = currentDisplayBounds
    }

    func moveCursor(to point: CGPoint) -> Bool {
        movedPoints.append(point)
        currentLocation = point
        return true
    }
}

private final class SpyMouseClickService: MouseClicking {
    var shouldSucceed = true
    private(set) var clickedPoints: [CGPoint] = []

    func leftClick(at point: CGPoint) -> Bool {
        clickedPoints.append(point)
        return shouldSucceed
    }
}
