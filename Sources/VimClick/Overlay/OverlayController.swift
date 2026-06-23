import AppKit

@MainActor
final class OverlayController {
    private let screenProvider: CursorScreenProvider
    private let keyboardMonitor: OverlayKeyboardMonitor
    private let coordinateSystem: GridCoordinateSystem
    private let gridView: GridView
    private let window: OverlayWindow
    private var selection = SelectionState()
    private var previouslyActiveApplication: NSRunningApplication?
    private var presentationPending = false

    init(
        screenProvider: CursorScreenProvider = CursorScreenProvider(),
        keyboardMonitor: OverlayKeyboardMonitor = OverlayKeyboardMonitor(),
        coordinateSystem: GridCoordinateSystem = GridCoordinateSystem()
    ) {
        self.screenProvider = screenProvider
        self.keyboardMonitor = keyboardMonitor
        self.coordinateSystem = coordinateSystem

        let gridView = GridView(coordinateSystem: coordinateSystem)
        self.gridView = gridView
        let window = OverlayWindow()
        window.contentView = gridView
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
        resetSelection()

        let applicationToRestore = previouslyActiveApplication
        previouslyActiveApplication = nil
        applicationToRestore?.activate(options: .activateIgnoringOtherApps)
    }

    private func present(restoringFocusTo activeApplication: NSRunningApplication?) {
        presentationPending = false
        guard let screen = screenProvider.currentScreen() else { return }

        previouslyActiveApplication = activeApplication
        window.setFrame(screen.frame, display: true)
        resetSelection()
        keyboardMonitor.start { [weak self] event in
            self?.handleKeyDown(event) ?? false
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        if event.keyCode == KeyboardKeyCodes.escape {
            hide()
            return true
        }

        let disallowedModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
        guard event.modifierFlags.intersection(disallowedModifiers).isEmpty,
              let characters = event.charactersIgnoringModifiers?.lowercased(),
              characters.count == 1,
              let character = characters.first else {
            return false
        }

        if selection.handleCharacter(character, coordinateSystem: coordinateSystem) {
            gridView.update(selection: selection)
        }

        // Printable input is consumed even when it is not a configured identifier.
        return true
    }

    private func resetSelection() {
        selection.reset()
        gridView.update(selection: selection)
    }
}
