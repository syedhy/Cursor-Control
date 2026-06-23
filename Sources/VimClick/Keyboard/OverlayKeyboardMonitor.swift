import AppKit

@MainActor
final class OverlayKeyboardMonitor {
    private var monitor: Any?

    func start(onKeyDown: @escaping @MainActor (NSEvent) -> Bool) {
        stop()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            onKeyDown(event) ? nil : event
        }
    }

    func stop() {
        guard let monitor else { return }

        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

}
