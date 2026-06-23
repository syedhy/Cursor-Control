import AppKit
import CoreGraphics

struct ScreenCoordinateConverter {
    func quartzPoint(from target: ClickTarget) -> CGPoint? {
        let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
        guard let screenNumber = target.screen.deviceDescription[screenNumberKey] as? NSNumber else {
            return nil
        }

        let displayID = CGDirectDisplayID(screenNumber.uint32Value)
        return quartzPoint(
            from: target.appKitPoint,
            appKitScreenFrame: target.screen.frame,
            quartzDisplayBounds: CGDisplayBounds(displayID)
        )
    }

    func quartzPoint(
        from appKitPoint: NSPoint,
        appKitScreenFrame: NSRect,
        quartzDisplayBounds: CGRect
    ) -> CGPoint {
        let horizontalPosition = (appKitPoint.x - appKitScreenFrame.minX) / appKitScreenFrame.width
        let verticalPosition = (appKitScreenFrame.maxY - appKitPoint.y) / appKitScreenFrame.height

        return CGPoint(
            x: quartzDisplayBounds.minX + (horizontalPosition * quartzDisplayBounds.width),
            y: quartzDisplayBounds.minY + (verticalPosition * quartzDisplayBounds.height)
        )
    }
}
