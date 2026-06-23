import AppKit
import Testing
@testable import VimClick

struct ScreenCoordinateConverterTests {
    private let converter = ScreenCoordinateConverter()

    @Test func convertsAppKitBottomLeftCoordinatesToQuartzTopLeftCoordinates() {
        let appKitFrame = NSRect(x: 0, y: 0, width: 200, height: 100)
        let quartzBounds = CGRect(x: 0, y: 0, width: 200, height: 100)

        #expect(converter.quartzPoint(
            from: NSPoint(x: 50, y: 75),
            appKitScreenFrame: appKitFrame,
            quartzDisplayBounds: quartzBounds
        ) == CGPoint(x: 50, y: 25))
    }

    @Test func convertsOffsetAndScaledDisplayCoordinates() {
        let appKitFrame = NSRect(x: -100, y: 50, width: 100, height: 100)
        let quartzBounds = CGRect(x: 300, y: 200, width: 200, height: 200)

        #expect(converter.quartzPoint(
            from: NSPoint(x: -75, y: 125),
            appKitScreenFrame: appKitFrame,
            quartzDisplayBounds: quartzBounds
        ) == CGPoint(x: 350, y: 250))
    }
}
