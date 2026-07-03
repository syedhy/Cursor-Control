Cursor Control Installation

1. Move Cursor Control.app into your Applications folder.
2. Open Cursor Control from Applications.
3. If macOS blocks the app, open System Settings > Privacy & Security, find the
   message for Cursor Control, click Open Anyway, then confirm Open.
4. Some macOS versions may also allow Control-clicking Cursor Control.app and
   choosing Open.
5. Grant Accessibility access when Cursor Control asks for it.

Why macOS may block it:

This release is ad-hoc signed and not Apple-notarized because it is distributed
without an Apple Developer Program account. Only install it from the official
GitHub release or Homebrew tap.

After it opens:

Cursor Control runs in the menu bar. It does not show a Dock icon or main
window. Use the menu bar icon to open the guide, settings, or quit the app.

Homebrew install:

brew tap syedhy/cursor-control
brew trust --cask syedhy/cursor-control/cursor-control
brew install --cask syedhy/cursor-control/cursor-control
