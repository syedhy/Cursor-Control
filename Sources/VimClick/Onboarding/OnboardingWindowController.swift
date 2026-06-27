import AppKit

@MainActor
final class OnboardingWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
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

        window.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "Welcome to VimClick"
        window.isReleasedWhenClosed = false
        window.animationBehavior = .documentWindow
        window.contentView = makeContentView()
    }

    private func makeContentView() -> NSView {
        let container = NSView()

        let title = NSTextField(labelWithString: "VimClick")
        title.font = .systemFont(ofSize: 28, weight: .semibold)

        let subtitle = NSTextField(
            wrappingLabelWithString: "Control the cursor and scroll anywhere on your Mac without leaving the keyboard."
        )
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabelColor
        subtitle.maximumNumberOfLines = 0

        let steps = NSStackView(
            views: [
                instruction(
                    title: "1. Enter cursor mode",
                    body: "Use the Cursor Control Mode shortcut from Settings. The menu bar icon changes while the mode is active."
                ),
                instruction(
                    title: "2. Move and click",
                    body: "Use the configured movement keys, H/J/K/L by default. Hold keys for acceleration. Press Return to left-click."
                ),
                instruction(
                    title: "3. Type normally in text fields",
                    body: "Cursor mode stays active after every click. Toggle cursor mode off with your shortcut when you want to type normally, then toggle it back on when you want mouse control again."
                ),
                instruction(
                    title: "4. Scroll any app",
                    body: "Use the scroll shortcuts to scroll left, down, up, or right. They work even while cursor mode is active."
                )
            ]
        )
        steps.orientation = .vertical
        steps.alignment = .leading
        steps.spacing = 14

        let settingsHint = NSTextField(
            wrappingLabelWithString: "Open Settings to tune movement keys, movement speed, acceleration, update rate, scroll distance, and shortcut assignments."
        )
        settingsHint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        settingsHint.textColor = .secondaryLabelColor
        settingsHint.maximumNumberOfLines = 0

        let stack = NSStackView(views: [title, subtitle, steps, settingsHint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -28)
        ])

        return container
    }

    private func instruction(title: String, body: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let bodyLabel = NSTextField(wrappingLabelWithString: body)
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.maximumNumberOfLines = 0

        let stack = NSStackView(views: [titleLabel, bodyLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }
}
