import Foundation

final class AutoClickerSettingsStore {
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "CursorControl.AutoClickerSettings.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func load() -> AutoClickerSettings {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(AutoClickerSettings.self, from: data) else {
            return AutoClickerSettings()
        }

        return AutoClickerSettings(
            clicksPerSecond: decoded.clicksPerSecond
        )
    }

    func save(_ settings: AutoClickerSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    func restoreDefaults() -> AutoClickerSettings {
        let settings = AutoClickerSettings()
        save(settings)
        return settings
    }
}
