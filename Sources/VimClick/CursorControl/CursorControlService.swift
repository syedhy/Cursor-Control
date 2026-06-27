import AppKit
import OSLog

@MainActor
final class CursorControlService {
    var onActiveStateChanged: ((Bool) -> Void)?
    var onCaptureModeChanged: ((CursorControlCaptureMode) -> Void)?
    var onCursorMoved: ((CGPoint) -> Void)?

    private let permissionService: any AccessibilityPermissionProviding
    private let permissionAlert: any AccessibilityPermissionAlerting
    private let cursorPositionService: any CursorPositionProviding
    private let mouseClickService: any MouseClicking
    private let settingsProvider: () -> CursorSettings
    private var accessibilityGuidanceState = AccessibilityGuidanceState()
    private var heldDirections: Set<CursorMovementDirection> = []
    private var movementTimer: Timer?
    private var movementTick = 0
    private(set) var isActive = false
    private(set) var captureMode: CursorControlCaptureMode = .movement
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "CursorControl"
    )

    init(
        permissionService: any AccessibilityPermissionProviding = AccessibilityPermissionService(),
        permissionAlert: any AccessibilityPermissionAlerting = AccessibilityPermissionAlert(),
        cursorPositionService: any CursorPositionProviding = QuartzCursorPositionService(),
        mouseClickService: any MouseClicking = MouseClickService(),
        settingsProvider: @escaping () -> CursorSettings = { CursorSettings() }
    ) {
        self.permissionService = permissionService
        self.permissionAlert = permissionAlert
        self.cursorPositionService = cursorPositionService
        self.mouseClickService = mouseClickService
        self.settingsProvider = settingsProvider
    }

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        guard ensureAccessibilityPermission() else { return }
        guard !isActive else { return }

        isActive = true
        captureMode = .movement
        heldDirections.removeAll()
        movementTick = 0
        onActiveStateChanged?(true)
        onCaptureModeChanged?(.movement)
        logger.notice("Cursor control mode started")
    }

    func stop() {
        guard isActive else { return }

        stopMovement()
        isActive = false
        captureMode = .movement
        onActiveStateChanged?(false)
        onCaptureModeChanged?(.movement)
        logger.notice("Cursor control mode stopped")
    }

    func refreshAccessibilityPermission() {
        accessibilityGuidanceState.refresh(isTrusted: permissionService.isTrusted)
    }

    func releaseAllMovementKeys() {
        stopMovement()
    }

    func handle(_ input: CursorControlInput) {
        guard isActive else { return }

        switch input {
        case .movementKeyDown(let direction):
            let wasStationary = heldDirections.isEmpty
            heldDirections.insert(direction)
            if wasStationary {
                movementTick = 0
                moveCursorOneFrame()
            }
            ensureMovementTimer()
        case .movementKeyUp(let direction):
            heldDirections.remove(direction)
            if heldDirections.isEmpty {
                stopMovement()
            }
        case .click:
            performClickWithoutExiting()
        }
    }

    private func ensureAccessibilityPermission() -> Bool {
        let isTrusted = permissionService.isTrusted
        guard isTrusted else {
            if accessibilityGuidanceState.shouldPresentGuidance(isTrusted: isTrusted),
               permissionAlert.presentMissingPermission() {
                permissionService.requestSystemPrompt()
                permissionService.openSystemSettings()
            }
            return false
        }

        accessibilityGuidanceState.refresh(isTrusted: true)
        return true
    }

    private func ensureMovementTimer() {
        guard movementTimer == nil else { return }

        let settings = settingsProvider()
        movementTimer = Timer.scheduledTimer(
            withTimeInterval: 1 / settings.frameRate,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.moveCursorOneFrame()
            }
        }
        RunLoop.main.add(movementTimer!, forMode: .common)
    }

    private func stopMovement() {
        movementTimer?.invalidate()
        movementTimer = nil
        heldDirections.removeAll()
        movementTick = 0
    }

    private func moveCursorOneFrame() {
        guard isActive, !heldDirections.isEmpty else {
            stopMovement()
            return
        }

        guard ensureAccessibilityPermission(),
              let currentLocation = cursorPositionService.currentLocation,
              let displayBounds = cursorPositionService.currentDisplayBounds else {
            stopMovement()
            return
        }

        let settings = settingsProvider()
        let nextPoint = CursorMotion.nextPoint(
            from: currentLocation,
            heldDirections: heldDirections,
            tick: movementTick,
            bounds: displayBounds,
            settings: settings
        )
        movementTick += 1
        if cursorPositionService.moveCursor(to: nextPoint) {
            onCursorMoved?(nextPoint)
        }
    }

    @discardableResult
    private func performClickWithoutExiting() -> Bool {
        guard ensureAccessibilityPermission(),
              let currentLocation = cursorPositionService.currentLocation else {
            return false
        }

        if !mouseClickService.leftClick(at: currentLocation) {
            permissionAlert.presentClickFailure()
            return false
        }

        return true
    }
}
