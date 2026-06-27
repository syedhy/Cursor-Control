import CoreGraphics
import Foundation

enum AppConstants {
    static let appName = "VimClick"
    static let bundleIdentifier = "io.github.vimclick.VimClick"
    static let minimumSystemVersion = "13.0"

    static let defaultScrollPixelDelta: Int32 = 20
    static let defaultScrollEventsPerShortcut = 2
    static let defaultScrollAccelerationPerRepeat = 0.2
    static let defaultScrollMaximumAccelerationMultiplier = 4.0
    static let defaultScrollVerticalMultiplier = 1.0
    static let defaultScrollHorizontalMultiplier = 1.0
    static let defaultCursorInitialSpeed = 0.5
    static let defaultCursorMaximumSpeed = 30.0
    static let defaultCursorAccelerationPerFrame = 1.0
    static let defaultCursorFrameRate = 60.0
    static let cursorModeIndicatorDotSize = 5.2
    static let cursorModeIndicatorHaloSize = 19.0
    static let cursorModeIndicatorOffsetX = 14.0
    static let cursorModeIndicatorOffsetY = -15.0
    static let cursorModeIndicatorTrailLength = 10
    static let cursorModeIndicatorTrailMaxLength = 32.0
    static let cursorModeIndicatorFrameRate = 60.0
    static let normalMenuBarIconSize = 18.0
}
