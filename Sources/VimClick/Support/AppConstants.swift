enum AppConstants {
    static let appName = "VimClick"
    static let bundleIdentifier = "io.github.vimclick.VimClick"
    static let minimumSystemVersion = "13.0"

    // Developer configuration. These values are intentionally not user settings.
    static let gridRows = Array("abcdefghijklmnopq")
    static let gridColumns = Array("abcdefghijklmnopqrstuvwxyz")
    static let precisionGridRows = Array("abcdefghijklmnopqrstuvwxy")
    static let precisionGridColumns = precisionGridRows
    static let maxZoomDepth = 1

    static let overlayBackgroundOpacity = 0.10
    static let gridLineOpacity = 0.24
    static let gridLineWidth = 0.75
}
