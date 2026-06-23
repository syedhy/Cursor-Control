import AppKit

@MainActor
final class OverlayController {
    private let screenProvider: CursorScreenProvider
    private let keyboardMonitor: OverlayKeyboardMonitor
    private let window: OverlayWindow
    private var previouslyActiveApplication: NSRunningApplication?
    private var presentationPending = false

    init(
        screenProvider: CursorScreenProvider = CursorScreenProvider(),
        keyboardMonitor: OverlayKeyboardMonitor = OverlayKeyboardMonitor()
    ) {
        self.screenProvider = screenProvider
        self.keyboardMonitor = keyboardMonitor

        let window = OverlayWindow()
        window.contentView = GridView()
        self.window = window
    }

    func show() {
        guard !window.isVisible, !presentationPending else { return }

        presentationPending = true
        let activeApplication = NSWorkspace.shared.frontmostApplication

        DispatchQueue.main.async { [weak self] in
            self?.present(restoringFocusTo: activeApplication)
        }
    }

    func handleApplicationDeactivation() {
        guard window.isVisible else { return }
        hide()
    }

    func hide() {
        presentationPending = false
        keyboardMonitor.stop()
        window.orderOut(nil)

        let applicationToRestore = previouslyActiveApplication
        previouslyActiveApplication = nil
        applicationToRestore?.activate(options: .activateIgnoringOtherApps)
    }

    private func present(restoringFocusTo activeApplication: NSRunningApplication?) {
        presentationPending = false
        guard let screen = screenProvider.currentScreen() else { return }

        previouslyActiveApplication = activeApplication
        window.setFrame(screen.frame, display: true)
        keyboardMonitor.start { [weak self] in
            self?.hide()
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
