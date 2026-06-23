import AppKit

@MainActor
final class OverlayController {
    private let screenProvider: CursorScreenProvider
    private let keyboardMonitor: OverlayKeyboardMonitor
    private let coordinateSystem: GridCoordinateSystem
    private let gridView: GridView
    private let window: OverlayWindow
    private var selection = SelectionState()
    private var zoom = ZoomState()
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
        resetInteractionState()

        let applicationToRestore = previouslyActiveApplication
        previouslyActiveApplication = nil
        applicationToRestore?.activate(options: .activateIgnoringOtherApps)
    }

    private func present(restoringFocusTo activeApplication: NSRunningApplication?) {
        presentationPending = false
        guard let screen = screenProvider.currentScreen() else { return }

        previouslyActiveApplication = activeApplication
        window.setFrame(screen.frame, display: true)
        resetInteractionState()
        keyboardMonitor.start { [weak self] event in
            self?.handleKeyDown(event) ?? false
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let command = KeyboardShortcuts.command(for: event) else {
            return false
        }

        switch command {
        case .cancel:
            hide()
            return true
        case .moveLeft:
            moveSelection(rowDelta: 0, columnDelta: -1)
            return true
        case .moveDown:
            moveSelection(rowDelta: 1, columnDelta: 0)
            return true
        case .moveUp:
            moveSelection(rowDelta: -1, columnDelta: 0)
            return true
        case .moveRight:
            moveSelection(rowDelta: 0, columnDelta: 1)
            return true
        case .zoom:
            zoomIntoSelection()
            return true
        case .typeCharacter(let character):
            guard zoom.allowsDirectSelection else { return true }

            if selection.handleCharacter(character, coordinateSystem: coordinateSystem) {
                updateGridView()
            }

            // Printable input is consumed even when it is not a configured identifier.
            return true
        }
    }

    private func moveSelection(rowDelta: Int, columnDelta: Int) {
        if selection.move(
            rowDelta: rowDelta,
            columnDelta: columnDelta,
            coordinateSystem: coordinateSystem
        ) {
            updateGridView()
        }
    }

    private func zoomIntoSelection() {
        guard case .cell(let coordinate) = selection.highlight else { return }
        guard zoom.zoom(into: coordinate, coordinateSystem: coordinateSystem) else { return }

        selection.reset()
        updateGridView()
    }

    private func resetInteractionState() {
        selection.reset()
        zoom.reset()
        updateGridView()
    }

    private func updateGridView() {
        gridView.update(selection: selection, zoom: zoom)
    }
}
