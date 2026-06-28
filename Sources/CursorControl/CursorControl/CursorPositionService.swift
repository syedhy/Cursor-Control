import CoreGraphics

protocol CursorPositionProviding {
    var currentLocation: CGPoint? { get }
    var currentDisplayBounds: CGRect? { get }
    func moveCursor(to point: CGPoint) -> Bool
}

struct QuartzCursorPositionService: CursorPositionProviding {
    var currentLocation: CGPoint? {
        CGEvent(source: nil)?.location
    }

    var currentDisplayBounds: CGRect? {
        guard let currentLocation else { return nil }

        var displayID = CGDirectDisplayID()
        var displayCount: UInt32 = 0
        let error = CGGetDisplaysWithPoint(currentLocation, 1, &displayID, &displayCount)
        guard error == .success, displayCount > 0 else {
            return nil
        }

        return CGDisplayBounds(displayID)
    }

    func moveCursor(to point: CGPoint) -> Bool {
        CGWarpMouseCursorPosition(point)
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            return false
        }

        event.post(tap: .cghidEventTap)
        return true
    }
}
