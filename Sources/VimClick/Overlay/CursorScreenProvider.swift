import AppKit

@MainActor
struct CursorScreenProvider {
    func currentScreen() -> NSScreen? {
        let cursorLocation = NSEvent.mouseLocation

        return NSScreen.screens.first {
            NSMouseInRect(cursorLocation, $0.frame, false)
        } ?? NSScreen.main
    }
}
