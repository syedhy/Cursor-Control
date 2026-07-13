cask "cursor-control" do
  version "1.1.0"
  sha256 "256fd3fe23666a17ff27d60a69f0994e599f5a1fd794eb68fcdd90f1181e81e6"

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
