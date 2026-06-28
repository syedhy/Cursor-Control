import Foundation

final class CursorSettingsStore {
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "VimClick.CursorSettings.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func load() -> CursorSettings {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(CursorSettings.self, from: data) else {
            return CursorSettings()
        }

        return CursorSettings(
            initialSpeed: decoded.initialSpeed,
            maximumSpeed: decoded.maximumSpeed,
            accelerationPerFrame: decoded.accelerationPerFrame,
            frameRate: decoded.frameRate,
            haloColor: decoded.haloColor
        )
    }

    func save(_ settings: CursorSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    func restoreDefaults() -> CursorSettings {
        let settings = CursorSettings()
        save(settings)
        return settings
    }
}
