import ApplicationServices
import AppKit
import CoreGraphics

protocol ScrollTargetProviding {
    var scrollLocation: CGPoint { get }
}

struct FrontmostScrollTargetProvider: ScrollTargetProviding {
    var scrollLocation: CGPoint {
        let mouseLoc = currentMouseLocation()
        if let frame = focusedWindowFrame(), !frame.contains(mouseLoc) {
            return frame.center
        }
        return mouseLoc
    }

    private func focusedWindowFrame() -> CGRect? {
        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication,
              frontmostApplication.bundleIdentifier != AppConstants.bundleIdentifier else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        guard let windowElement = focusedWindowElement(from: appElement),
              let position = cgPointAttribute(kAXPositionAttribute, from: windowElement),
              let size = cgSizeAttribute(kAXSizeAttribute, from: windowElement) else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    private func focusedWindowElement(from appElement: AXUIElement) -> AXUIElement? {
        if let focusedWindow = elementAttribute(kAXFocusedWindowAttribute, from: appElement) {
            return focusedWindow
        }

        return elementAttribute(kAXMainWindowAttribute, from: appElement)
    }

    private func elementAttribute(_ attribute: String, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    private func cgPointAttribute(_ attribute: String, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard
              AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func cgSizeAttribute(_ attribute: String, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard
              AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    private func currentMouseLocation() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
