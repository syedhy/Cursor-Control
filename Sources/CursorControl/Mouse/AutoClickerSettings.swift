import Foundation

struct AutoClickerSettings: Codable, Equatable {
    var clicksPerSecond: Double = 10.0

    static let minimumClicksPerSecond: Double = 1.0
    static let maximumClicksPerSecond: Double = 100.0
}
