enum ShortcutIdentifier: String, CaseIterable, Codable, Hashable {
    case activateCursorMode
    case scrollLeft
    case scrollDown
    case scrollUp
    case scrollRight

    static let eventTapHandledCases: [ShortcutIdentifier] = [
        .scrollLeft,
        .scrollDown,
        .scrollUp,
        .scrollRight
    ]

    static let carbonHandledCases: [ShortcutIdentifier] = allCases.filter {
        !eventTapHandledCases.contains($0)
    }

    var hotKeyID: UInt32 {
        switch self {
        case .activateCursorMode:
            return 1
        case .scrollLeft:
            return 2
        case .scrollDown:
            return 3
        case .scrollUp:
            return 4
        case .scrollRight:
            return 5
        }
    }

    var title: String {
        switch self {
        case .activateCursorMode:
            return "Cursor control mode"
        case .scrollLeft:
            return "Scroll left"
        case .scrollDown:
            return "Scroll down"
        case .scrollUp:
            return "Scroll up"
        case .scrollRight:
            return "Scroll right"
        }
    }

    var settingsDescription: String {
        switch self {
        case .activateCursorMode:
            return "Enter or exit keyboard cursor-control mode."
        case .scrollLeft:
            return "Scroll the frontmost app left."
        case .scrollDown:
            return "Scroll the frontmost app down."
        case .scrollUp:
            return "Scroll the frontmost app up."
        case .scrollRight:
            return "Scroll the frontmost app right."
        }
    }
}
