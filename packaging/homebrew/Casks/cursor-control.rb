cask "cursor-control" do
  version "1.0.0"
  sha256 "7d826a5c7d0a0b95b98cdd109f241e8a2456179a7d9bd423daf628cebcf739c4"

  url "https://github.com/syedhy/Cursor-Control/releases/download/v#{version}/CursorControl-#{version}-macOS.zip"
  name "Cursor Control"
  desc "Keyboard-driven cursor movement and scrolling for macOS"
  homepage "https://github.com/syedhy/Cursor-Control"

  depends_on macos: :ventura

  app "CursorControl-#{version}-macOS/Cursor Control.app"

  zap trash: [
    "~/Library/Preferences/io.github.cursorcontrol.CursorControl.plist",
  ]

  caveats <<~EOS
    Cursor Control is currently ad-hoc signed and not Apple-notarized.
    On first launch, macOS may block it.

    If that happens:
      1. Open System Settings > Privacy & Security.
      2. Scroll to the security message for Cursor Control.
      3. Click Open Anyway, then confirm Open.

    Some macOS versions may also allow Control-clicking Cursor Control.app
    in Applications and choosing Open.

    Cursor Control requires Accessibility access for keyboard-requested
    cursor movement, clicking, and scrolling.
  EOS
end
