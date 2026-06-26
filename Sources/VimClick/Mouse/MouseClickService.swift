import CoreGraphics
import Foundation

protocol MouseClicking {
    func leftClick(at point: CGPoint) -> Bool
}

struct MouseClickService {
    func leftClick(at point: CGPoint) -> Bool {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        eventSource?.localEventsSuppressionInterval = 0

        if let mouseMove = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) {
            mouseMove.post(tap: .cghidEventTap)
        }

        guard let mouseDown = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ), let mouseUp = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            return false
        }

        mouseDown.setIntegerValueField(.mouseEventClickState, value: 1)
        mouseUp.setIntegerValueField(.mouseEventClickState, value: 1)
        mouseDown.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.045)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }
}

extension MouseClickService: MouseClicking {}
