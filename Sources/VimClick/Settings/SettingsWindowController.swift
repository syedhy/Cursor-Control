import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
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
            wrappingLabelWithString: "Shortcut and overlay preferences will be available in a later phase."
        )
        detailLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 0

        let stack = NSStackView(views: [titleLabel, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 28)
        ])

        return container
    }
}
