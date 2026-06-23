import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onActivate: () -> Void
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    init(
        onActivate: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onActivate = onActivate
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        configureMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let image = NSImage(
            systemSymbolName: "cursorarrow.click.2",
            accessibilityDescription: AppConstants.appName
        )
        image?.isTemplate = true
        button.image = image
        button.toolTip = AppConstants.appName
    }

    private func configureMenu() {
        let menu = NSMenu()

        menu.addItem(
            withTitle: "Activate VimClick",
            action: #selector(activate),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit VimClick",
            action: #selector(quit),
            keyEquivalent: "q"
        )

        for item in menu.items where item.action != nil {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func activate() {
        onActivate()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
