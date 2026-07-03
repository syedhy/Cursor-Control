#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
VERSION="${VERSION:-1.0.0}"
REPO="${REPO:-syedhy/Cursor-Control}"
PACKAGE_NAME="${PACKAGE_NAME:-CursorControl-$VERSION-macOS}"
ZIP_PATH="${ZIP_PATH:-$DIST_DIR/$PACKAGE_NAME.zip}"
CASK_DIR="${CASK_DIR:-$ROOT_DIR/packaging/homebrew/Casks}"
CASK_PATH="$CASK_DIR/cursor-control.rb"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Release zip not found at: $ZIP_PATH" >&2
  echo "Run script/package_release.sh first." >&2
  exit 1
fi

SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

mkdir -p "$CASK_DIR"

cat >"$CASK_PATH" <<CASK
cask "cursor-control" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/$REPO/releases/download/v#{version}/CursorControl-#{version}-macOS.zip"
  name "Cursor Control"
  desc "Keyboard-driven cursor movement and scrolling for macOS"
  homepage "https://github.com/$REPO"

  depends_on macos: ">= :ventura"

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
CASK

echo "Homebrew cask written to:"
echo "$CASK_PATH"
