struct ScrollSettings: Codable, Equatable {
    static let minimumPixelDelta: Int32 = 1
    static let maximumPixelDelta: Int32 = 5_000
    static let minimumEventsPerShortcut = 1
    static let maximumEventsPerShortcut = 20
    static let minimumAccelerationPerRepeat = 0.0
    static let maximumAccelerationPerRepeat = 1.0
    static let minimumMaximumMultiplier = 1.0
    static let maximumMaximumMultiplier = 12.0
    static let minimumAxisMultiplier = 0.1
    static let maximumAxisMultiplier = 5.0

    var pixelDelta: Int32
    var eventsPerShortcut: Int
    var accelerationPerRepeat: Double
    var maximumAccelerationMultiplier: Double
    var verticalMultiplier: Double
    var horizontalMultiplier: Double

    enum CodingKeys: String, CodingKey {
        case pixelDelta
        case eventsPerShortcut
        case accelerationPerRepeat
        case maximumAccelerationMultiplier
        case verticalMultiplier
        case horizontalMultiplier
    }

    init(
        pixelDelta: Int32 = AppConstants.defaultScrollPixelDelta,
        eventsPerShortcut: Int = AppConstants.defaultScrollEventsPerShortcut,
        accelerationPerRepeat: Double = AppConstants.defaultScrollAccelerationPerRepeat,
        maximumAccelerationMultiplier: Double = AppConstants.defaultScrollMaximumAccelerationMultiplier,
        verticalMultiplier: Double = AppConstants.defaultScrollVerticalMultiplier,
        horizontalMultiplier: Double = AppConstants.defaultScrollHorizontalMultiplier
    ) {
        self.pixelDelta = min(
            max(pixelDelta, Self.minimumPixelDelta),
            Self.maximumPixelDelta
        )
        self.eventsPerShortcut = min(
            max(eventsPerShortcut, Self.minimumEventsPerShortcut),
            Self.maximumEventsPerShortcut
        )
        self.accelerationPerRepeat = min(
            max(accelerationPerRepeat, Self.minimumAccelerationPerRepeat),
            Self.maximumAccelerationPerRepeat
        )
        self.maximumAccelerationMultiplier = min(
            max(maximumAccelerationMultiplier, Self.minimumMaximumMultiplier),
            Self.maximumMaximumMultiplier
        )
        self.verticalMultiplier = min(
            max(verticalMultiplier, Self.minimumAxisMultiplier),
            Self.maximumAxisMultiplier
        )
        self.horizontalMultiplier = min(
            max(horizontalMultiplier, Self.minimumAxisMultiplier),
            Self.maximumAxisMultiplier
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            pixelDelta: try container.decodeIfPresent(Int32.self, forKey: .pixelDelta)
                ?? AppConstants.defaultScrollPixelDelta,
            eventsPerShortcut: try container.decodeIfPresent(Int.self, forKey: .eventsPerShortcut)
                ?? AppConstants.defaultScrollEventsPerShortcut,
            accelerationPerRepeat: try container.decodeIfPresent(Double.self, forKey: .accelerationPerRepeat)
                ?? AppConstants.defaultScrollAccelerationPerRepeat,
            maximumAccelerationMultiplier: try container.decodeIfPresent(Double.self, forKey: .maximumAccelerationMultiplier)
                ?? AppConstants.defaultScrollMaximumAccelerationMultiplier,
            verticalMultiplier: try container.decodeIfPresent(Double.self, forKey: .verticalMultiplier)
                ?? AppConstants.defaultScrollVerticalMultiplier,
            horizontalMultiplier: try container.decodeIfPresent(Double.self, forKey: .horizontalMultiplier)
                ?? AppConstants.defaultScrollHorizontalMultiplier
        )
    }

    func effectivePixelDelta(
        for direction: ScrollDirection,
        repeatCount: Int
    ) -> Int32 {
        let axisMultiplier = direction.isVertical ? verticalMultiplier : horizontalMultiplier
        let accelerationMultiplier = min(
            maximumAccelerationMultiplier,
            1 + (Double(max(0, repeatCount)) * accelerationPerRepeat)
        )
        let effectiveDelta = Double(pixelDelta) * axisMultiplier * accelerationMultiplier
        return Int32(min(Double(Self.maximumPixelDelta), max(1, effectiveDelta.rounded())))
    }
}
