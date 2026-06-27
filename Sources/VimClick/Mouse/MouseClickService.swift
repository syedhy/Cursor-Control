import CoreGraphics
import Foundation

enum MouseClickKind: Equatable {
    case left
    case doubleLeft
    case right
}

protocol MouseClicking {
    func click(_ kind: MouseClickKind, at point: CGPoint) -> Bool
}

struct MouseClickService {
    func click(_ kind: MouseClickKind, at point: CGPoint) -> Bool {
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

        let mouseButton: CGMouseButton
        let downType: CGEventType
        let upType: CGEventType
        let clickState: Int64

        switch kind {
        case .left:
            mouseButton = .left
            downType = .leftMouseDown
            upType = .leftMouseUp
            clickState = 1
        case .doubleLeft:
            mouseButton = .left
            downType = .leftMouseDown
            upType = .leftMouseUp
            clickState = 2
        case .right:
            mouseButton = .right
            downType = .rightMouseDown
            upType = .rightMouseUp
            clickState = 1
        }

        guard let mouseDown = CGEvent(
            mouseEventSource: eventSource,
            mouseType: downType,
            mouseCursorPosition: point,
            mouseButton: mouseButton
        ), let mouseUp = CGEvent(
            mouseEventSource: eventSource,
            mouseType: upType,
            mouseCursorPosition: point,
            mouseButton: mouseButton
        ) else {
            return false
        }

        mouseDown.setIntegerValueField(.mouseEventClickState, value: clickState)
        mouseUp.setIntegerValueField(.mouseEventClickState, value: clickState)
        mouseDown.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.045)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }
}

extension MouseClickService: MouseClicking {}
