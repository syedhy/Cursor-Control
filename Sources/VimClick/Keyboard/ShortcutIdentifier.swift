enum ShortcutIdentifier: String, CaseIterable, Codable, Hashable {
    case activateOverlay
    case activateCursorMode
    case scrollLeft
    case scrollDown
    case scrollUp
    case scrollRight

    var hotKeyID: UInt32 {
        switch self {
        case .activateOverlay:
            return 1
        case .activateCursorMode:
            return 2
        case .scrollLeft:
            return 3
        case .scrollDown:
            return 4
        case .scrollUp:
            return 5
        case .scrollRight:
            return 6
        }
    }

    var title: String {
        switch self {
        case .activateOverlay:
            return "Activate overlay"
        case .activateCursorMode:
            return "Activate cursor mode"
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
        case .activateOverlay:
            return "Show the click grid anywhere on your Mac."
        case .activateCursorMode:
            return "Reserved for Phase 10 cursor-control mode."
        case .scrollLeft, .scrollDown, .scrollUp, .scrollRight:
            return "Reserved for Phase 9 universal scrolling."
        }
    }
}
