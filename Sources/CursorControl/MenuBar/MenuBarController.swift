import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onToggleCursorMode: () -> Void
    private let onShowGuide: () -> Void
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void
    private var cursorModeItem: NSMenuItem?

    init(
        cursorModeShortcut: KeyboardShortcut,
        onToggleCursorMode: @escaping () -> Void,
        onShowGuide: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleCursorMode = onToggleCursorMode
        self.onShowGuide = onShowGuide
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        configureMenu(cursorModeShortcut: cursorModeShortcut)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = Self.statusImage(isCursorModeActive: false)
        button.toolTip = AppConstants.appName
    }

    func updateCursorModeShortcut(_ shortcut: KeyboardShortcut) {
        cursorModeItem?.keyEquivalent = shortcut.keyEquivalent
        cursorModeItem?.keyEquivalentModifierMask = shortcut.keyEquivalentModifierMask
    }

    func setCursorModeActive(_ isActive: Bool) {
        cursorModeItem?.state = isActive ? .on : .off
        cursorModeItem?.title = isActive ? "Exit Cursor Control Mode" : "Cursor Control Mode"
        guard let button = statusItem.button else { return }

        button.image = Self.statusImage(isCursorModeActive: isActive)
        button.toolTip = isActive
            ? "Cursor Control mode active"
            : AppConstants.appName
    }

    private static func statusImage(isCursorModeActive: Bool) -> NSImage? {
        if isCursorModeActive {
            let image = NSImage(
                systemSymbolName: "cursorarrow.motionlines",
                accessibilityDescription: "Cursor Control cursor control mode active"
            )
            image?.isTemplate = true
            return image
        }

        if let image = NSImage(
            systemSymbolName: "cursorarrow.click.2",
            accessibilityDescription: AppConstants.appName
        ) {
            image.isTemplate = true
            return image
        }

        let fallback = NSImage(
            systemSymbolName: "command.square",
            accessibilityDescription: AppConstants.appName
        )
        fallback?.isTemplate = true
        return fallback
    }

    private func configureMenu(cursorModeShortcut: KeyboardShortcut) {
        let menu = NSMenu()

        let cursorModeItem = menu.addItem(
            withTitle: "Cursor Control Mode",
            action: #selector(toggleCursorMode),
            keyEquivalent: cursorModeShortcut.keyEquivalent
        )
        cursorModeItem.keyEquivalentModifierMask = cursorModeShortcut.keyEquivalentModifierMask
        self.cursorModeItem = cursorModeItem
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "How to Use Cursor Control…",
            action: #selector(showGuide),
            keyEquivalent: "?"
        )
        menu.addItem(
            withTitle: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Cursor Control",
            action: #selector(quit),
            keyEquivalent: "q"
        )

        for item in menu.items where item.action != nil {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func toggleCursorMode() {
        onToggleCursorMode()
    }

    @objc private func showGuide() {
        onShowGuide()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
