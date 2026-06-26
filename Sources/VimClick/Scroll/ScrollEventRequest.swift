import Darwin
import CoreGraphics

struct ScrollEventRequest: Equatable {
    let verticalDelta: Int32
    let horizontalDelta: Int32
    let screenLocation: CGPoint
}
