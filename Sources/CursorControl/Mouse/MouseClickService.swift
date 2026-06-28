import CoreGraphics
import Foundation

enum MouseClickKind: Equatable {
    case left
    case doubleLeft
    case right
}

protocol MouseClicking {
    func click(_ kind: MouseClickKind, at point: CGPoint) -> Bool
    func beginLeftDrag(at point: CGPoint) -> Bool
    func dragLeftMouse(to point: CGPoint) -> Bool
    func endLeftDrag(at point: CGPoint) -> Bool
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
            configureSyntheticMouseEvent(mouseMove)
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

        configureSyntheticMouseEvent(mouseDown, clickState: clickState)
        configureSyntheticMouseEvent(mouseUp, clickState: clickState)
        mouseDown.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.045)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }

    func beginLeftDrag(at point: CGPoint) -> Bool {
        postMouseEvent(.mouseMoved, at: point, button: .left)
            && postMouseEvent(.leftMouseDown, at: point, button: .left)
    }

    func dragLeftMouse(to point: CGPoint) -> Bool {
        postMouseEvent(.leftMouseDragged, at: point, button: .left)
    }

    func endLeftDrag(at point: CGPoint) -> Bool {
        postMouseEvent(.leftMouseUp, at: point, button: .left)
    }

    private func postMouseEvent(
        _ type: CGEventType,
        at point: CGPoint,
        button: CGMouseButton
    ) -> Bool {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        eventSource?.localEventsSuppressionInterval = 0

        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else {
            return false
        }

        configureSyntheticMouseEvent(event)
        event.post(tap: .cghidEventTap)
        return true
    }

    private func configureSyntheticMouseEvent(
        _ event: CGEvent,
        clickState: Int64 = 0
    ) {
        // A drag is intentionally triggered by the physical Shift key, but apps
        // such as Finder treat Shift-click as range selection. Strip keyboard
        // modifier flags from synthetic mouse events so the drag behaves like a
        // plain trackpad/mouse drag at the current cursor location.
        event.flags = []
        if clickState > 0 {
            event.setIntegerValueField(.mouseEventClickState, value: clickState)
        }
    }
}

extension MouseClickService: MouseClicking {}
