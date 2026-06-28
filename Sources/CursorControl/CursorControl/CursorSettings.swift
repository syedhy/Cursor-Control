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

    static let minimumHaloSize = 4.0
    static let maximumHaloSize = 60.0
    static let minimumHaloOpacity = 0.1
    static let maximumHaloOpacity = 1.0

    var initialSpeed: Double
    var maximumSpeed: Double
    var accelerationPerFrame: Double
    var frameRate: Double
    var haloColor: HaloColor
    var haloSize: Double
    var haloOpacity: Double

    init(
        initialSpeed: Double = AppConstants.defaultCursorInitialSpeed,
        maximumSpeed: Double = AppConstants.defaultCursorMaximumSpeed,
        accelerationPerFrame: Double = AppConstants.defaultCursorAccelerationPerFrame,
        frameRate: Double = AppConstants.defaultCursorFrameRate,
        haloColor: HaloColor = .blue,
        haloSize: Double = 12.0,
        haloOpacity: Double = 1.0
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
        self.haloSize = min(max(haloSize, Self.minimumHaloSize), Self.maximumHaloSize)
        self.haloOpacity = min(max(haloOpacity, Self.minimumHaloOpacity), Self.maximumHaloOpacity)
    }

    enum CodingKeys: String, CodingKey {
        case initialSpeed, maximumSpeed, accelerationPerFrame, frameRate, haloColor, haloSize, haloOpacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        initialSpeed = try container.decodeIfPresent(Double.self, forKey: .initialSpeed) ?? AppConstants.defaultCursorInitialSpeed
        maximumSpeed = try container.decodeIfPresent(Double.self, forKey: .maximumSpeed) ?? AppConstants.defaultCursorMaximumSpeed
        accelerationPerFrame = try container.decodeIfPresent(Double.self, forKey: .accelerationPerFrame) ?? AppConstants.defaultCursorAccelerationPerFrame
        frameRate = try container.decodeIfPresent(Double.self, forKey: .frameRate) ?? AppConstants.defaultCursorFrameRate
        haloColor = try container.decodeIfPresent(HaloColor.self, forKey: .haloColor) ?? .blue
        haloSize = try container.decodeIfPresent(Double.self, forKey: .haloSize) ?? 12.0
        haloOpacity = try container.decodeIfPresent(Double.self, forKey: .haloOpacity) ?? 1.0
        
        initialSpeed = min(max(initialSpeed, Self.minimumInitialSpeed), Self.maximumInitialSpeed)
        maximumSpeed = min(max(maximumSpeed, max(initialSpeed, Self.minimumMaximumSpeed)), Self.maximumMaximumSpeed)
        accelerationPerFrame = min(max(accelerationPerFrame, Self.minimumAccelerationPerFrame), Self.maximumAccelerationPerFrame)
        frameRate = min(max(frameRate, Self.minimumFrameRate), Self.maximumFrameRate)
        haloSize = min(max(haloSize, Self.minimumHaloSize), Self.maximumHaloSize)
        haloOpacity = min(max(haloOpacity, Self.minimumHaloOpacity), Self.maximumHaloOpacity)
    }
}
