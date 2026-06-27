import Foundation

struct CursorSettings: Codable, Equatable {
    static let minimumInitialSpeed = 0.01
    static let maximumInitialSpeed = 80.0
    static let minimumMaximumSpeed = 0.01
    static let maximumMaximumSpeed = 160.0
    static let minimumAccelerationPerFrame = 0.0
    static let maximumAccelerationPerFrame = 5.0
    static let minimumFrameRate = 10.0
    static let maximumFrameRate = 144.0

    var initialSpeed: Double
    var maximumSpeed: Double
    var accelerationPerFrame: Double
    var frameRate: Double

    init(
        initialSpeed: Double = AppConstants.defaultCursorInitialSpeed,
        maximumSpeed: Double = AppConstants.defaultCursorMaximumSpeed,
        accelerationPerFrame: Double = AppConstants.defaultCursorAccelerationPerFrame,
        frameRate: Double = AppConstants.defaultCursorFrameRate
    ) {
        let clampedInitialSpeed = min(
            max(initialSpeed, Self.minimumInitialSpeed),
            Self.maximumInitialSpeed
        )
        self.initialSpeed = clampedInitialSpeed
        self.maximumSpeed = min(
            max(maximumSpeed, max(clampedInitialSpeed, Self.minimumMaximumSpeed)),
            Self.maximumMaximumSpeed
        )
        self.accelerationPerFrame = min(
            max(accelerationPerFrame, Self.minimumAccelerationPerFrame),
            Self.maximumAccelerationPerFrame
        )
        self.frameRate = min(
            max(frameRate, Self.minimumFrameRate),
            Self.maximumFrameRate
        )
    }
}
