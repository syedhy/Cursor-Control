import Foundation
import AppKit

enum HaloColor: String, Codable, CaseIterable {
    case blue
    case yellow
    case red
    case black
    case white
    
    var nsColor: NSColor {
        switch self {
        case .blue: return .systemBlue
        case .yellow: return .systemYellow
        case .red: return .systemRed
        case .black: return .black
        case .white: return .white
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .red: return "Red"
        case .black: return "Black"
        case .white: return "White"
        }
    }
}
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
    var haloColor: HaloColor

    init(
        initialSpeed: Double = AppConstants.defaultCursorInitialSpeed,
        maximumSpeed: Double = AppConstants.defaultCursorMaximumSpeed,
        accelerationPerFrame: Double = AppConstants.defaultCursorAccelerationPerFrame,
        frameRate: Double = AppConstants.defaultCursorFrameRate,
        haloColor: HaloColor = .blue
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
        self.haloColor = haloColor
    }
}
