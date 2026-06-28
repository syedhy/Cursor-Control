import Darwin
import CoreGraphics

enum ScrollDirection: CaseIterable, Equatable {
    case left
    case down
    case up
    case right

    var isVertical: Bool {
        switch self {
        case .up, .down:
            return true
        case .left, .right:
            return false
        }
    }

    func eventRequest(
        screenLocation: CGPoint,
        pixelDelta: Int32 = AppConstants.defaultScrollPixelDelta
    ) -> ScrollEventRequest {
        switch self {
        case .left:
            return ScrollEventRequest(
                verticalDelta: 0,
                horizontalDelta: pixelDelta,
                screenLocation: screenLocation
            )
        case .down:
            return ScrollEventRequest(
                verticalDelta: -pixelDelta,
                horizontalDelta: 0,
                screenLocation: screenLocation
            )
        case .up:
            return ScrollEventRequest(
                verticalDelta: pixelDelta,
                horizontalDelta: 0,
                screenLocation: screenLocation
            )
        case .right:
            return ScrollEventRequest(
                verticalDelta: 0,
                horizontalDelta: -pixelDelta,
                screenLocation: screenLocation
            )
        }
    }
}
