import AppKit

@MainActor
final class ShortcutRecorderButton: NSButton {
    let shortcutIdentifier: ShortcutIdentifier
    var onCapturedShortcut: ((KeyboardShortcut) -> Void)?
    var onCancelledRecording: (() -> Void)?

    private var titleBeforeRecording = ""
    private(set) var isRecordingShortcut = false

    init(shortcutIdentifier: ShortcutIdentifier) {
        self.shortcutIdentifier = shortcutIdentifier
        super.init(frame: .zero)
        setButtonType(.momentaryPushIn)
        bezelStyle = .rounded
        controlSize = .regular
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    func beginRecording() {
        titleBeforeRecording = title
        isRecordingShortcut = true
        title = "Type shortcut…"
        needsDisplay = true
        window?.makeFirstResponder(self)
    }

    func finishRecording(displayTitle: String) {
        isRecordingShortcut = false
        title = displayTitle
        window?.makeFirstResponder(nil)
        needsDisplay = true
    }

    func cancelRecording() {
        isRecordingShortcut = false
        title = titleBeforeRecording
        window?.makeFirstResponder(nil)
        needsDisplay = true
        onCancelledRecording?()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecordingShortcut else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == KeyboardShortcuts.escapeKeyCode {
            cancelRecording()
            return
        }

        guard let shortcut = KeyboardShortcut(event: event) else {
            NSSound.beep()
            return
        }

        onCapturedShortcut?(shortcut)
    }
}
