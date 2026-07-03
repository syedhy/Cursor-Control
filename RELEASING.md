# Releasing Cursor Control

Cursor Control is distributed without an Apple Developer Program account. Release
artifacts are ad-hoc signed, not Apple-notarized, and published as versioned zip
files through GitHub Releases.

## Release Artifact

The release package has this layout:

```text
dist/
  CursorControl-1.0.0-macOS/
    Cursor Control.app
    README_INSTALL.txt
  CursorControl-1.0.0-macOS.zip
  CursorControl-1.0.0-macOS.zip.sha256
```

## Build And Verify

Run the full test suite first:

```bash
swift test
```

Create the release zip:

```bash
VERSION=1.0.0 ./script/package_release.sh
```

Verify the package:

```bash
VERSION=1.0.0 ./script/verify_release_package.sh
```

The verification script expects Gatekeeper to reject the app unless a future
release is Developer ID signed and notarized.

## GitHub Release

Create and push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Create a GitHub Release for the tag and upload:

```text
dist/CursorControl-1.0.0-macOS.zip
dist/CursorControl-1.0.0-macOS.zip.sha256
```

## Homebrew Cask

After the zip exists locally, generate the cask:

```bash
VERSION=1.0.0 ./script/generate_homebrew_cask.sh
```

The generated cask is written to:

```text
packaging/homebrew/Casks/cursor-control.rb
```

Copy that file into the Homebrew tap repository, then test it locally:

```bash
brew install --cask ./Casks/cursor-control.rb
brew uninstall --cask cursor-control
```

If the tap is public, users can install with:

```bash
brew tap syedhy/cursor-control
brew install --cask cursor-control
```

If Homebrew warns that the cask is not trusted, users may need:

```bash
brew trust --cask syedhy/cursor-control/cursor-control
```

## First Launch

Because the app is not notarized, macOS may block it on first launch. Users
should open System Settings > Privacy & Security and choose Open Anyway for
Cursor Control, or Control-click the app and choose Open on macOS versions where
that works.
