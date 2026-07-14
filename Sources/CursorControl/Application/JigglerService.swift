import AppKit
import CoreGraphics
import Foundation
import OSLog

@MainActor
final class JigglerService {
    var onActiveStateChanged: ((Bool) -> Void)?

    private(set) var isActive = false
    private var timer: Timer?
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "JigglerService"
    )

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        onActiveStateChanged?(true)
        logger.notice("Mouse jiggler started")

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleTimeAndJiggle()
            }
        }
        timer?.tolerance = 1.0
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        guard isActive else { return }
        isActive = false
        timer?.invalidate()
        timer = nil
        onActiveStateChanged?(false)
        logger.notice("Mouse jiggler stopped")
    }

    private func checkIdleTimeAndJiggle() {
        guard isActive else { return }

        // ~0 is kCGAnyInputEventType which checks overall system idle time
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: CGEventType(rawValue: ~0)!
        )

        if idleTime >= 30.0 {
            jiggle()
        }
    }

    private func jiggle() {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        eventSource?.localEventsSuppressionInterval = 0

        guard let point = CGEvent(source: nil)?.location else { return }

        // Move 1 pixel right
        if let moveRight = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: point.x + 1, y: point.y),
            mouseButton: .left
        ) {
            moveRight.flags = []
            moveRight.post(tap: .cghidEventTap)
        }

        // Wait a tiny bit and move back 1 pixel left to restore original position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let moveLeft = CGEvent(
                mouseEventSource: eventSource,
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left
            ) {
                moveLeft.flags = []
                moveLeft.post(tap: .cghidEventTap)
            }
        }
    }
}
