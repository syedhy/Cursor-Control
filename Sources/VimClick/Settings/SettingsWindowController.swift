import AppKit

private enum SettingsSection: Int, CaseIterable {
    case shortcuts
    case scrolling
    case cursorControl

    var title: String {
        switch self {
        case .shortcuts:
            return "Shortcuts"
        case .scrolling:
            return "Scrolling"
        case .cursorControl:
            return "Cursor Control"
        }
    }
}

private enum ScrollSettingKey {
    case pixelDelta
    case eventsPerShortcut
    case accelerationPerRepeat
    case maximumAccelerationMultiplier
    case verticalMultiplier
    case horizontalMultiplier
}

private enum CursorSettingKey {
    case initialSpeed
    case maximumSpeed
    case accelerationPerFrame
    case frameRate
}

@MainActor
private final class NumericSettingControl {
    let slider: NSSlider
    let field: NSTextField
    let isInteger: Bool
    let suffix: String
    private let minimum: Double
    private let maximum: Double

    init(
        minimum: Double,
        maximum: Double,
        isInteger: Bool,
        suffix: String,
        target: AnyObject,
        action: Selector
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.isInteger = isInteger
        self.suffix = suffix

        slider = NSSlider(
            value: minimum,
            minValue: minimum,
            maxValue: maximum,
            target: target,
            action: action
        )
        slider.widthAnchor.constraint(equalToConstant: 210).isActive = true

        field = NSTextField(string: "")
        field.target = target
        field.action = action
        field.alignment = .right
        field.widthAnchor.constraint(equalToConstant: 86).isActive = true
    }

    func row(title: String, description: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        let descriptionLabel = NSTextField(wrappingLabelWithString: description)
        descriptionLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.maximumNumberOfLines = 0

        let labelStack = NSStackView(views: [titleLabel, descriptionLabel])
        labelStack.orientation = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 3
        labelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 250).isActive = true

        let suffixLabel = NSTextField(labelWithString: suffix)
        suffixLabel.textColor = .secondaryLabelColor
        suffixLabel.widthAnchor.constraint(equalToConstant: 54).isActive = true

        let row = NSStackView(views: [labelStack, slider, field, suffixLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    func setValue(_ value: Double) {
        let clamped = clamped(value)
        slider.doubleValue = clamped
        field.stringValue = formatted(clamped)
    }

    func value(sender: Any?) -> Double {
        if let sender = sender as? NSSlider, sender === slider {
            return normalized(slider.doubleValue)
        }

        if let sender = sender as? NSTextField, sender === field {
            return normalized(field.doubleValue)
        }

        return normalized(field.doubleValue)
    }

    private func normalized(_ value: Double) -> Double {
        let clamped = clamped(value)
        return isInteger ? clamped.rounded() : clamped
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, minimum), maximum)
    }

    private func formatted(_ value: Double) -> String {
        if isInteger {
            return "\(Int(value.rounded()))"
        }

        return String(format: "%.2f", value)
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    private let shortcutProvider: (ShortcutIdentifier) -> KeyboardShortcut
    private let scrollSettingsProvider: () -> ScrollSettings
    private let cursorSettingsProvider: () -> CursorSettings
    private let cursorMovementBindingProvider: (CursorMovementDirection) -> KeyboardShortcut
    private let onShortcutChange: (ShortcutIdentifier, KeyboardShortcut) -> ShortcutUpdateResult
    private let onRestoreDefaults: () -> ShortcutUpdateResult
    private let onScrollSettingsChange: (ScrollSettings) -> Void
    private let onRestoreScrollSettingsDefaults: () -> ScrollSettings
    private let onCursorSettingsChange: (CursorSettings) -> Void
    private let onRestoreCursorSettingsDefaults: () -> CursorSettings
    private let onCursorMovementBindingChange: (
        CursorMovementDirection,
        KeyboardShortcut
    ) -> Result<CursorMovementBindings, CursorMovementBindingValidationError>
    private let onRestoreCursorMovementBindingsDefaults: () -> CursorMovementBindings
    private let onRecordingStateChanged: (Bool) -> Void
    private var shortcutButtons: [ShortcutIdentifier: ShortcutRecorderButton] = [:]
    private var cursorMovementButtons: [CursorMovementDirection: ShortcutRecorderButton] = [:]
    private var scrollControls: [ScrollSettingKey: NumericSettingControl] = [:]
    private var cursorControls: [CursorSettingKey: NumericSettingControl] = [:]
    private var recordingEventMonitor: Any?
    private let messageLabel = NSTextField(labelWithString: "")
    private let tabView = NSTabView()

    init(
        shortcutProvider: @escaping (ShortcutIdentifier) -> KeyboardShortcut,
        scrollSettingsProvider: @escaping () -> ScrollSettings,
        cursorSettingsProvider: @escaping () -> CursorSettings,
        cursorMovementBindingProvider: @escaping (CursorMovementDirection) -> KeyboardShortcut,
        onShortcutChange: @escaping (ShortcutIdentifier, KeyboardShortcut) -> ShortcutUpdateResult,
        onRestoreDefaults: @escaping () -> ShortcutUpdateResult,
        onScrollSettingsChange: @escaping (ScrollSettings) -> Void,
        onRestoreScrollSettingsDefaults: @escaping () -> ScrollSettings,
        onCursorSettingsChange: @escaping (CursorSettings) -> Void,
        onRestoreCursorSettingsDefaults: @escaping () -> CursorSettings,
        onCursorMovementBindingChange: @escaping (
            CursorMovementDirection,
            KeyboardShortcut
        ) -> Result<CursorMovementBindings, CursorMovementBindingValidationError>,
        onRestoreCursorMovementBindingsDefaults: @escaping () -> CursorMovementBindings,
        onRecordingStateChanged: @escaping (Bool) -> Void
    ) {
        self.shortcutProvider = shortcutProvider
        self.scrollSettingsProvider = scrollSettingsProvider
        self.cursorSettingsProvider = cursorSettingsProvider
        self.cursorMovementBindingProvider = cursorMovementBindingProvider
        self.onShortcutChange = onShortcutChange
        self.onRestoreDefaults = onRestoreDefaults
        self.onScrollSettingsChange = onScrollSettingsChange
        self.onRestoreScrollSettingsDefaults = onRestoreScrollSettingsDefaults
        self.onCursorSettingsChange = onCursorSettingsChange
        self.onRestoreCursorSettingsDefaults = onRestoreCursorSettingsDefaults
        self.onCursorMovementBindingChange = onCursorMovementBindingChange
        self.onRestoreCursorMovementBindingsDefaults = onRestoreCursorMovementBindingsDefaults
        self.onRecordingStateChanged = onRecordingStateChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 720),
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
        refreshScrollSettingsControls()
        refreshCursorSettingsControls()
        refreshCursorMovementButtons()
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
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let titleLabel = NSTextField(labelWithString: "VimClick Settings")
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let detailLabel = NSTextField(
            wrappingLabelWithString: "Tune shortcuts, scrolling, and cursor-control behavior. VimClick is focused on keyboard cursor movement and universal scrolling."
        )
        detailLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 0

        messageLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.maximumNumberOfLines = 0

        configureTabView()

        let restoreButton = NSButton(
            title: "Restore All Defaults",
            target: self,
            action: #selector(restoreDefaults)
        )
        restoreButton.bezelStyle = .rounded

        let stack = NSStackView(
            views: [
                titleLabel,
                detailLabel,
                tabView,
                messageLabel,
                restoreButton
            ]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        documentView.addSubview(stack)
        container.addSubview(scrollView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            tabView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            tabView.heightAnchor.constraint(equalToConstant: 560),

            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -24)
        ])

        refreshShortcutButtons()
        refreshScrollSettingsControls()
        refreshCursorSettingsControls()
        refreshCursorMovementButtons()
        return container
    }

    private func configureTabView() {
        tabView.tabViewType = .topTabsBezelBorder
        tabView.addTabViewItem(tabItem(.shortcuts, view: makeShortcutsSection()))
        tabView.addTabViewItem(tabItem(.scrolling, view: makeScrollSettingsSection()))
        tabView.addTabViewItem(tabItem(.cursorControl, view: makeCursorSettingsSection()))
        tabView.selectTabViewItem(at: 0)
    }

    private func tabItem(_ section: SettingsSection, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: section.rawValue)
        item.label = section.title
        item.view = paddedTabContent(view)
        return item
    }

    private func paddedTabContent(_ content: NSView) -> NSView {
        let container = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -18),
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            content.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -18)
        ])
        return container
    }

    private func makeShortcutsSection() -> NSView {
        let sectionLabel = sectionDescription(
            title: "Shortcuts",
            body: "Record global shortcuts here. Cursor movement keys are configured separately in Cursor Control."
        )

        let shortcutStack = NSStackView()
        shortcutStack.orientation = .vertical
        shortcutStack.alignment = .leading
        shortcutStack.spacing = 14

        for identifier in ShortcutIdentifier.allCases {
            shortcutStack.addArrangedSubview(makeShortcutRow(for: identifier))
        }

        let stack = NSStackView(views: [sectionLabel, shortcutStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        return stack
    }

    private func makeScrollSettingsSection() -> NSView {
        let sectionLabel = sectionDescription(
            title: "Scrolling",
            body: "Fine-tune universal scrolling. Use exact numeric values for tiny one-pixel nudges or larger fast-scroll movement."
        )

        let rows: [(ScrollSettingKey, String, String, Double, Double, Bool, String)] = [
            (
                .pixelDelta,
                "Base distance",
                "Pixels sent by one scroll event before multipliers and acceleration.",
                Double(ScrollSettings.minimumPixelDelta),
                Double(ScrollSettings.maximumPixelDelta),
                true,
                "px"
            ),
            (
                .eventsPerShortcut,
                "Events per repeat",
                "How many scroll events VimClick sends for each shortcut press or repeat.",
                Double(ScrollSettings.minimumEventsPerShortcut),
                Double(ScrollSettings.maximumEventsPerShortcut),
                true,
                "events"
            ),
            (
                .accelerationPerRepeat,
                "Hold acceleration",
                "Extra multiplier added for every held-key repeat. Use 0 for perfectly linear scrolling.",
                ScrollSettings.minimumAccelerationPerRepeat,
                ScrollSettings.maximumAccelerationPerRepeat,
                false,
                "x/repeat"
            ),
            (
                .maximumAccelerationMultiplier,
                "Acceleration cap",
                "Maximum multiplier allowed while holding a scroll shortcut.",
                ScrollSettings.minimumMaximumMultiplier,
                ScrollSettings.maximumMaximumMultiplier,
                false,
                "x"
            ),
            (
                .verticalMultiplier,
                "Vertical multiplier",
                "Scales up/down scroll distance without affecting left/right.",
                ScrollSettings.minimumAxisMultiplier,
                ScrollSettings.maximumAxisMultiplier,
                false,
                "x"
            ),
            (
                .horizontalMultiplier,
                "Horizontal multiplier",
                "Scales left/right scroll distance without affecting up/down.",
                ScrollSettings.minimumAxisMultiplier,
                ScrollSettings.maximumAxisMultiplier,
                false,
                "x"
            )
        ]

        let stack = NSStackView(views: [sectionLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        for row in rows {
            let control = NumericSettingControl(
                minimum: row.3,
                maximum: row.4,
                isInteger: row.5,
                suffix: row.6,
                target: self,
                action: #selector(scrollSettingChanged(_:))
            )
            scrollControls[row.0] = control
            stack.addArrangedSubview(control.row(title: row.1, description: row.2))
        }

        return stack
    }

    private func makeCursorSettingsSection() -> NSView {
        let sectionLabel = sectionDescription(
            title: "Cursor Control",
            body: "Tune Vim cursor movement for both pixel-level control and fast corner-to-corner travel."
        )

        let rows: [(CursorSettingKey, String, String, Double, Double, Bool, String)] = [
            (
                .initialSpeed,
                "Initial speed",
                "Pixels moved by the first movement frame. Lower values make single taps more precise.",
                CursorSettings.minimumInitialSpeed,
                CursorSettings.maximumInitialSpeed,
                false,
                "px/frame"
            ),
            (
                .maximumSpeed,
                "Maximum speed",
                "Top cursor speed while holding a movement key.",
                CursorSettings.minimumMaximumSpeed,
                CursorSettings.maximumMaximumSpeed,
                false,
                "px/frame"
            ),
            (
                .accelerationPerFrame,
                "Acceleration",
                "How quickly held cursor movement ramps from initial speed to maximum speed.",
                CursorSettings.minimumAccelerationPerFrame,
                CursorSettings.maximumAccelerationPerFrame,
                false,
                "px/frame²"
            ),
            (
                .frameRate,
                "Update rate",
                "How often VimClick updates cursor movement while keys are held.",
                CursorSettings.minimumFrameRate,
                CursorSettings.maximumFrameRate,
                false,
                "Hz"
            )
        ]

        let stack = NSStackView(views: [sectionLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        for row in rows {
            let control = NumericSettingControl(
                minimum: row.3,
                maximum: row.4,
                isInteger: row.5,
                suffix: row.6,
                target: self,
                action: #selector(cursorSettingChanged(_:))
            )
            cursorControls[row.0] = control
            stack.addArrangedSubview(control.row(title: row.1, description: row.2))
        }

        let bindingDescription = sectionDescription(
            title: "Movement Keys",
            body: "Choose the keys VimClick captures while cursor control mode is active. Plain keys like H/J/K/L and modified keys like Shift-H are both allowed."
        )
        stack.addArrangedSubview(bindingDescription)

        let bindingStack = NSStackView()
        bindingStack.orientation = .vertical
        bindingStack.alignment = .leading
        bindingStack.spacing = 12

        for direction in CursorMovementDirection.allCases {
            bindingStack.addArrangedSubview(makeCursorMovementRow(for: direction))
        }
        stack.addArrangedSubview(bindingStack)

        return stack
    }

    private func sectionDescription(title: String, body: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let bodyLabel = NSTextField(wrappingLabelWithString: body)
        bodyLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.maximumNumberOfLines = 0

        let stack = NSStackView(views: [titleLabel, bodyLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
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
        labelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        return row
    }

    private func makeCursorMovementRow(for direction: CursorMovementDirection) -> NSView {
        let titleLabel = NSTextField(labelWithString: direction.settingsTitle)
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        let descriptionLabel = NSTextField(wrappingLabelWithString: direction.settingsDescription)
        descriptionLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.maximumNumberOfLines = 0

        let labelStack = NSStackView(views: [titleLabel, descriptionLabel])
        labelStack.orientation = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 3

        let button = ShortcutRecorderButton(cursorMovementDirection: direction)
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
        cursorMovementButtons[direction] = button

        let row = NSStackView(views: [labelStack, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 18
        row.translatesAutoresizingMaskIntoConstraints = false
        labelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        return row
    }

    @objc private func beginShortcutRecording(_ sender: ShortcutRecorderButton) {
        for button in shortcutButtons.values where button !== sender && button.isRecordingShortcut {
            button.cancelRecording()
        }
        for button in cursorMovementButtons.values where button !== sender && button.isRecordingShortcut {
            button.cancelRecording()
        }

        showMessage("Press the new key for \(sender.recorderTarget.title), or Esc to cancel.", isError: false)
        onRecordingStateChanged(true)
        sender.beginRecording()
        startRecordingEventMonitor(for: sender)
    }

    private func finishShortcutRecording(
        _ button: ShortcutRecorderButton,
        shortcut: KeyboardShortcut
    ) {
        stopRecordingEventMonitor()

        switch button.recorderTarget {
        case .globalShortcut(let identifier):
            finishGlobalShortcutRecording(button, identifier: identifier, shortcut: shortcut)
        case .cursorMovement(let direction):
            finishCursorMovementRecording(button, direction: direction, shortcut: shortcut)
        }
    }

    private func finishGlobalShortcutRecording(
        _ button: ShortcutRecorderButton,
        identifier: ShortcutIdentifier,
        shortcut: KeyboardShortcut
    ) {
        let result = onShortcutChange(identifier, shortcut)
        refreshShortcutButtons()
        button.finishRecording(displayTitle: shortcutProvider(identifier).displayName)
        onRecordingStateChanged(false)

        switch result {
        case .success:
            showMessage("Updated \(identifier.title) to \(shortcut.displayName).", isError: false)
        case .validationFailure(let message):
            showMessage(message, isError: true)
        case .registrationFailure(let message):
            showMessage(message, isError: true)
        }
    }

    private func finishCursorMovementRecording(
        _ button: ShortcutRecorderButton,
        direction: CursorMovementDirection,
        shortcut: KeyboardShortcut
    ) {
        let result = onCursorMovementBindingChange(direction, shortcut)
        refreshCursorMovementButtons()
        button.finishRecording(displayTitle: cursorMovementBindingProvider(direction).displayName)
        onRecordingStateChanged(false)

        switch result {
        case .success:
            showMessage("Updated \(direction.settingsTitle.lowercased()) to \(shortcut.displayName).", isError: false)
        case .failure(let error):
            showMessage(error.localizedDescription, isError: true)
        }
    }

    @objc private func restoreDefaults() {
        let result = onRestoreDefaults()
        let scrollSettings = onRestoreScrollSettingsDefaults()
        let cursorSettings = onRestoreCursorSettingsDefaults()
        _ = onRestoreCursorMovementBindingsDefaults()
        refreshShortcutButtons()
        refreshScrollSettingsControls(with: scrollSettings)
        refreshCursorSettingsControls(with: cursorSettings)
        refreshCursorMovementButtons()

        switch result {
        case .success:
            showMessage("Restored all VimClick defaults.", isError: false)
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

    private func refreshCursorMovementButtons() {
        for (direction, button) in cursorMovementButtons {
            guard !button.isRecordingShortcut else { continue }
            button.title = cursorMovementBindingProvider(direction).displayName
        }
    }

    @objc private func scrollSettingChanged(_ sender: Any) {
        let settings = ScrollSettings(
            pixelDelta: Int32(readScroll(.pixelDelta, sender: sender)),
            eventsPerShortcut: Int(readScroll(.eventsPerShortcut, sender: sender)),
            accelerationPerRepeat: readScroll(.accelerationPerRepeat, sender: sender),
            maximumAccelerationMultiplier: readScroll(.maximumAccelerationMultiplier, sender: sender),
            verticalMultiplier: readScroll(.verticalMultiplier, sender: sender),
            horizontalMultiplier: readScroll(.horizontalMultiplier, sender: sender)
        )
        onScrollSettingsChange(settings)
        refreshScrollSettingsControls(with: settings)
        showMessage("Updated scroll tuning.", isError: false)
    }

    @objc private func cursorSettingChanged(_ sender: Any) {
        let settings = CursorSettings(
            initialSpeed: readCursor(.initialSpeed, sender: sender),
            maximumSpeed: readCursor(.maximumSpeed, sender: sender),
            accelerationPerFrame: readCursor(.accelerationPerFrame, sender: sender),
            frameRate: readCursor(.frameRate, sender: sender)
        )
        onCursorSettingsChange(settings)
        refreshCursorSettingsControls(with: settings)
        showMessage("Updated cursor-control tuning.", isError: false)
    }

    private func readScroll(_ key: ScrollSettingKey, sender: Any?) -> Double {
        scrollControls[key]?.value(sender: sender) ?? 0
    }

    private func readCursor(_ key: CursorSettingKey, sender: Any?) -> Double {
        cursorControls[key]?.value(sender: sender) ?? 0
    }

    private func refreshScrollSettingsControls(with settings: ScrollSettings? = nil) {
        let settings = settings ?? scrollSettingsProvider()
        scrollControls[.pixelDelta]?.setValue(Double(settings.pixelDelta))
        scrollControls[.eventsPerShortcut]?.setValue(Double(settings.eventsPerShortcut))
        scrollControls[.accelerationPerRepeat]?.setValue(settings.accelerationPerRepeat)
        scrollControls[.maximumAccelerationMultiplier]?.setValue(settings.maximumAccelerationMultiplier)
        scrollControls[.verticalMultiplier]?.setValue(settings.verticalMultiplier)
        scrollControls[.horizontalMultiplier]?.setValue(settings.horizontalMultiplier)
    }

    private func refreshCursorSettingsControls(with settings: CursorSettings? = nil) {
        let settings = settings ?? cursorSettingsProvider()
        cursorControls[.initialSpeed]?.setValue(settings.initialSpeed)
        cursorControls[.maximumSpeed]?.setValue(settings.maximumSpeed)
        cursorControls[.accelerationPerFrame]?.setValue(settings.accelerationPerFrame)
        cursorControls[.frameRate]?.setValue(settings.frameRate)
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

            guard let shortcut = KeyboardShortcut(
                event: event,
                requiresPrimaryModifier: button.recorderTarget.requiresPrimaryModifier
            ) else {
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
