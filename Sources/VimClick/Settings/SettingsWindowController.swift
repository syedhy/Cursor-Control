import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    private let shortcutProvider: (ShortcutIdentifier) -> KeyboardShortcut
    private let onShortcutChange: (ShortcutIdentifier, KeyboardShortcut) -> ShortcutUpdateResult
    private let onRestoreDefaults: () -> ShortcutUpdateResult
    private let onRecordingStateChanged: (Bool) -> Void
    private var shortcutButtons: [ShortcutIdentifier: ShortcutRecorderButton] = [:]
    private var recordingEventMonitor: Any?
    private let messageLabel = NSTextField(labelWithString: "")

    init(
        shortcutProvider: @escaping (ShortcutIdentifier) -> KeyboardShortcut,
        onShortcutChange: @escaping (ShortcutIdentifier, KeyboardShortcut) -> ShortcutUpdateResult,
        onRestoreDefaults: @escaping () -> ShortcutUpdateResult,
        onRecordingStateChanged: @escaping (Bool) -> Void
    ) {
        self.shortcutProvider = shortcutProvider
        self.onShortcutChange = onShortcutChange
        self.onRestoreDefaults = onRestoreDefaults
        self.onRecordingStateChanged = onRecordingStateChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        configureWindow(window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show() {
        guard let window else { return }

        refreshShortcutButtons()
        window.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "VimClick Settings"
        window.isReleasedWhenClosed = false
        window.animationBehavior = .documentWindow
        window.contentView = makeContentView()
    }

    private func makeContentView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: "VimClick Settings")
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let detailLabel = NSTextField(
            wrappingLabelWithString: "Record global shortcuts here. Grid size, row identifiers, column identifiers, and zoom depth stay developer-configured."
        )
        detailLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 0

        messageLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.maximumNumberOfLines = 0

        let shortcutStack = NSStackView()
        shortcutStack.orientation = .vertical
        shortcutStack.alignment = .leading
        shortcutStack.spacing = 14

        for identifier in ShortcutIdentifier.allCases {
            shortcutStack.addArrangedSubview(makeShortcutRow(for: identifier))
        }

        let restoreButton = NSButton(
            title: "Restore Defaults",
            target: self,
            action: #selector(restoreDefaults)
        )
        restoreButton.bezelStyle = .rounded

        let footerLabel = NSTextField(
            wrappingLabelWithString: "Cursor mode and scrolling shortcuts are configurable now so the first release can keep one stable shortcut system. Their behavior arrives in Phases 9 and 10."
        )
        footerLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        footerLabel.textColor = .secondaryLabelColor
        footerLabel.maximumNumberOfLines = 0

        let stack = NSStackView(
            views: [titleLabel, detailLabel, shortcutStack, messageLabel, restoreButton, footerLabel]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24)
        ])

        refreshShortcutButtons()
        return container
    }

    private func makeShortcutRow(for identifier: ShortcutIdentifier) -> NSView {
        let titleLabel = NSTextField(labelWithString: identifier.title)
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        let descriptionLabel = NSTextField(wrappingLabelWithString: identifier.settingsDescription)
        descriptionLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.maximumNumberOfLines = 0

        let labelStack = NSStackView(views: [titleLabel, descriptionLabel])
        labelStack.orientation = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 3

        let button = ShortcutRecorderButton(shortcutIdentifier: identifier)
        button.target = self
        button.action = #selector(beginShortcutRecording(_:))
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        button.onCapturedShortcut = { [weak self, weak button] shortcut in
            guard let self, let button else { return }
            self.finishShortcutRecording(button, shortcut: shortcut)
        }
        button.onCancelledRecording = { [weak self] in
            self?.cancelShortcutRecording()
        }
        shortcutButtons[identifier] = button

        let row = NSStackView(views: [labelStack, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 18
        row.translatesAutoresizingMaskIntoConstraints = false
        labelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        return row
    }

    @objc private func beginShortcutRecording(_ sender: ShortcutRecorderButton) {
        for button in shortcutButtons.values where button !== sender && button.isRecordingShortcut {
            button.cancelRecording()
        }

        showMessage("Press the new shortcut for \(sender.shortcutIdentifier.title), or Esc to cancel.", isError: false)
        onRecordingStateChanged(true)
        sender.beginRecording()
        startRecordingEventMonitor(for: sender)
    }

    private func finishShortcutRecording(
        _ button: ShortcutRecorderButton,
        shortcut: KeyboardShortcut
    ) {
        stopRecordingEventMonitor()

        let identifier = button.shortcutIdentifier
        let result = onShortcutChange(identifier, shortcut)
        refreshShortcutButtons()
        button.finishRecording(displayTitle: shortcutProvider(identifier).displayName)

        switch result {
        case .success:
            showMessage("Updated \(identifier.title) to \(shortcut.displayName).", isError: false)
        case .validationFailure(let message):
            onRecordingStateChanged(false)
            showMessage(message, isError: true)
        case .registrationFailure(let message):
            showMessage(message, isError: true)
        }
    }

    @objc private func restoreDefaults() {
        let result = onRestoreDefaults()
        refreshShortcutButtons()

        switch result {
        case .success:
            showMessage("Restored default shortcuts.", isError: false)
        case .validationFailure(let message), .registrationFailure(let message):
            showMessage(message, isError: true)
        }
    }

    private func refreshShortcutButtons() {
        for (identifier, button) in shortcutButtons {
            guard !button.isRecordingShortcut else { continue }
            button.title = shortcutProvider(identifier).displayName
        }
    }

    private func showMessage(_ message: String, isError: Bool) {
        messageLabel.stringValue = message
        messageLabel.textColor = isError ? .systemRed : .secondaryLabelColor
    }

    private func startRecordingEventMonitor(for button: ShortcutRecorderButton) {
        stopRecordingEventMonitor()
        recordingEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak self, weak button] event in
            guard let self, let button, button.isRecordingShortcut else {
                return event
            }

            if event.keyCode == KeyboardShortcuts.escapeKeyCode {
                button.cancelRecording()
                return nil
            }

            guard let shortcut = KeyboardShortcut(event: event) else {
                NSSound.beep()
                return nil
            }

            self.finishShortcutRecording(button, shortcut: shortcut)
            return nil
        }
    }

    private func stopRecordingEventMonitor() {
        if let recordingEventMonitor {
            NSEvent.removeMonitor(recordingEventMonitor)
            self.recordingEventMonitor = nil
        }
    }

    private func cancelShortcutRecording() {
        stopRecordingEventMonitor()
        onRecordingStateChanged(false)
        showMessage("Recording cancelled.", isError: false)
    }
}
