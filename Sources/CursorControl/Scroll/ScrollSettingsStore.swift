import Foundation

final class ScrollSettingsStore {
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "CursorControl.ScrollSettings.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func load() -> ScrollSettings {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(ScrollSettings.self, from: data) else {
            return ScrollSettings()
        }

        return ScrollSettings(
            pixelDelta: decoded.pixelDelta,
            eventsPerShortcut: decoded.eventsPerShortcut,
            accelerationPerRepeat: decoded.accelerationPerRepeat,
            maximumAccelerationMultiplier: decoded.maximumAccelerationMultiplier,
            verticalMultiplier: decoded.verticalMultiplier,
            horizontalMultiplier: decoded.horizontalMultiplier
        )
    }

    func save(_ settings: ScrollSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    func restoreDefaults() -> ScrollSettings {
        let settings = ScrollSettings()
        save(settings)
        return settings
    }
}
