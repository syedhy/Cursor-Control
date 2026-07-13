import Foundation
import CoreGraphics

@MainActor
final class AutoClickerService {
    private var isRunning = false
    private var task: Task<Void, Never>?
    private let settingsProvider: () -> AutoClickerSettings
    private let mouseClickService: MouseClicking

    init(settingsProvider: @escaping () -> AutoClickerSettings, mouseClickService: MouseClicking) {
        self.settingsProvider = settingsProvider
        self.mouseClickService = mouseClickService
    }

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        isRunning = true
        task = Task {
            while !Task.isCancelled {
                let settings = self.settingsProvider()
                let interval = 1.0 / settings.clicksPerSecond

                if let event = CGEvent(source: nil) {
                    let point = event.location
                    _ = self.mouseClickService.fastLeftClick(at: point)
                }

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    private func stop() {
        isRunning = false
        task?.cancel()
        task = nil
    }
}
