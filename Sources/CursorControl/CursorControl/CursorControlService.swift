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
    private let dateProvider: () -> Date
    private let doubleClickInterval: TimeInterval
    private var accessibilityGuidanceState = AccessibilityGuidanceState()
    private var heldDirections: Set<CursorMovementDirection> = []
    private var movementTimer: Timer?
    private var movementTick = 0
    private var lastLeftClick: (date: Date, point: CGPoint)?
    private var isLeftDragging = false
    private var lastDragPoint: CGPoint?
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
        settingsProvider: @escaping () -> CursorSettings = { CursorSettings() },
        dateProvider: @escaping () -> Date = Date.init,
        doubleClickInterval: TimeInterval = NSEvent.doubleClickInterval
    ) {
        self.permissionService = permissionService
        self.permissionAlert = permissionAlert
        self.cursorPositionService = cursorPositionService
        self.mouseClickService = mouseClickService
        self.settingsProvider = settingsProvider
        self.dateProvider = dateProvider
        self.doubleClickInterval = doubleClickInterval
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
        lastLeftClick = nil
        isLeftDragging = false
        lastDragPoint = nil
        onActiveStateChanged?(true)
        onCaptureModeChanged?(.movement)
        logger.notice("Cursor control mode started")
    }

    func stop() {
        guard isActive else { return }

        stopMovement()
        lastLeftClick = nil
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
            stopMovementIfIdle()
        case .dragHoldChanged(let isPressed):
            setLeftDragHeld(isPressed)
        case .leftClick:
            performClickWithoutExiting(.left)
        case .rightClick:
            performClickWithoutExiting(.right)
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
        stopMovementTimer()
        endLeftDragIfNeeded()
        heldDirections.removeAll()
        lastLeftClick = nil
    }

    private func stopMovementIfIdle() {
        if heldDirections.isEmpty {
            stopMovementTimer()
        }
    }

    private func stopMovementTimer() {
        movementTimer?.invalidate()
        movementTimer = nil
        movementTick = 0
    }

    private func setLeftDragHeld(_ isPressed: Bool) {
        if isPressed {
            guard ensureAccessibilityPermission(),
                  let currentLocation = cursorPositionService.currentLocation else {
                return
            }
            _ = beginLeftDragIfNeeded(at: currentLocation)
        } else {
            endLeftDragIfNeeded()
        }
    }

    private func moveCursorOneFrame() {
        guard isActive, !heldDirections.isEmpty else {
            stopMovementTimer()
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

        if isLeftDragging {
            if mouseClickService.dragLeftMouse(to: nextPoint) {
                lastDragPoint = nextPoint
                onCursorMoved?(nextPoint)
            } else {
                permissionAlert.presentClickFailure()
                stopMovement()
            }
            return
        }

        endLeftDragIfNeeded()
        if cursorPositionService.moveCursor(to: nextPoint) {
            onCursorMoved?(nextPoint)
        }
    }

    private func beginLeftDragIfNeeded(at point: CGPoint) -> Bool {
        guard !isLeftDragging else { return true }

        guard mouseClickService.beginLeftDrag(at: point) else {
            permissionAlert.presentClickFailure()
            return false
        }

        isLeftDragging = true
        lastDragPoint = point
        lastLeftClick = nil
        return true
    }

    private func endLeftDragIfNeeded() {
        guard isLeftDragging else { return }

        let releasePoint = lastDragPoint ?? cursorPositionService.currentLocation ?? .zero
        if !mouseClickService.endLeftDrag(at: releasePoint) {
            permissionAlert.presentClickFailure()
        }
        isLeftDragging = false
        lastDragPoint = nil
    }

    @discardableResult
    private func performClickWithoutExiting(_ requestedKind: MouseClickKind) -> Bool {
        guard ensureAccessibilityPermission(),
              let currentLocation = cursorPositionService.currentLocation else {
            return false
        }

        let kind = effectiveClickKind(
            requestedKind: requestedKind,
            currentLocation: currentLocation
        )

        if !mouseClickService.click(kind, at: currentLocation) {
            permissionAlert.presentClickFailure()
            return false
        }

        updateClickTracking(after: kind, at: currentLocation)
        return true
    }

    private func effectiveClickKind(
        requestedKind: MouseClickKind,
        currentLocation: CGPoint
    ) -> MouseClickKind {
        guard requestedKind == .left else {
            return requestedKind
        }

        let now = dateProvider()
        guard let lastLeftClick,
              now.timeIntervalSince(lastLeftClick.date) <= doubleClickInterval,
              currentLocation.distance(to: lastLeftClick.point) <= AppConstants.doubleClickMaximumDistance else {
            return .left
        }

        return .doubleLeft
    }

    private func updateClickTracking(after kind: MouseClickKind, at point: CGPoint) {
        switch kind {
        case .left:
            lastLeftClick = (dateProvider(), point)
        case .doubleLeft, .right:
            lastLeftClick = nil
        }
    }
}

private extension CGPoint {
    func distance(to otherPoint: CGPoint) -> CGFloat {
        let deltaX = x - otherPoint.x
        let deltaY = y - otherPoint.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
}
