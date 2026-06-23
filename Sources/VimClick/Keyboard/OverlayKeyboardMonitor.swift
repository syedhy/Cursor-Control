import AppKit

@MainActor
final class OverlayKeyboardMonitor {
    private var monitor: Any?

    func start(onCancel: @escaping @MainActor () -> Void) {
        stop()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == KeyboardKeyCodes.escape else {
                return event
            }

            onCancel()
            return nil
        }
    }

    func stop() {
        guard let monitor else { return }

        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

}
