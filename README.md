# Cursor Control

[![Release](https://img.shields.io/github/v/release/syedhy/Cursor-Control?label=release)](https://github.com/syedhy/Cursor-Control/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13%2B-lightgrey.svg)](#requirements)

Cursor Control is a native macOS menu bar app for moving the mouse cursor,
clicking, dragging, and scrolling with the keyboard. It is built with AppKit,
has no web runtime, and stays out of the Dock.

> [!NOTE]
> Cursor Control releases are ad-hoc signed and not Apple-notarized because the
> project is distributed without an Apple Developer Program account. macOS may
> require approving the app from Privacy & Security on first launch.

## Install

### Homebrew

```bash
brew tap syedhy/cursor-control
brew trust --cask syedhy/cursor-control/cursor-control
brew install --cask syedhy/cursor-control/cursor-control
```

### GitHub Release

1. Download `CursorControl-1.0.0-macOS.zip` from the [latest release](https://github.com/syedhy/Cursor-Control/releases/latest).
2. Unzip it.
3. Move `Cursor Control.app` to the Applications folder.
4. Open `Cursor Control.app`.
5. If macOS blocks the app, open **System Settings > Privacy & Security** and click **Open Anyway** for Cursor Control.
6. Grant Accessibility access when prompted.

Some macOS versions may also allow Control-clicking `Cursor Control.app` in
Applications and choosing **Open**.

## Includes

- Vim-style cursor movement with **H/J/K/L**
- Keyboard click, double-click, right-click, and Shift-drag support
- Universal scrolling with **Control-H/J/K/L**
- Configurable global shortcuts, movement keys, scroll tuning, and cursor speed
- Menu bar only presence with onboarding and settings windows
- GitHub Release zip and Homebrew cask distribution

## Goals

- Native AppKit interface with no web runtime
- Fast, keyboard-first cursor movement and scrolling
- Lightweight menu bar presence
- Clear, maintainable architecture
- Straightforward GitHub Releases distribution

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later, or the matching Xcode Command Line Tools
- Swift 6 compatible toolchain

## Usage

Opening `Cursor Control.app` adds a cursor icon to the macOS menu bar. It does not
open a main application window or appear in the Dock.

The menu bar menu contains:

- **Cursor Control Mode** — enter or exit keyboard cursor-control mode
- **How to Use Cursor Control…** — open the onboarding guide
- **Settings…** — configure shortcuts, scrolling, and cursor movement
- **Quit Cursor Control** — exit the application

### Cursor Control Mode

Cursor Control Mode lets you move the visible mouse cursor directly from the
keyboard. Press **Option-W** by default to enter or exit cursor mode. While it
is active:

- **H/J/K/L** move the real cursor left, down, up, and right
- Holding movement keys accelerates smoothly
- Holding two movement keys moves diagonally
- Hold **Shift** to hold the left mouse button down, move with **H/J/K/L**, then
  release **Shift** to drop or stop drawing
- **Return** left-clicks at the current cursor location
- Press **Return** twice quickly to double-click
- **Shift-Return** or **Control-Return** right-clicks

Cursor mode stays active after clicks. Toggle cursor mode off with the shortcut
when you want normal typing, then toggle it back on when you want keyboard mouse
control again.

### Scrolling

Scrolling works globally without opening any extra window. Press
**Control-H/J/K/L** to scroll left, down, up, and right in the frontmost app.

Scroll shortcuts also work while Cursor Control Mode is active.

Settings lets you tune the scroll distance from single-pixel movement up to
fast movement, the number of scroll events per repeat, hold acceleration, and
acceleration cap.

## Default global shortcuts

- **Option-W** — enter or exit cursor-control mode
- **Control-H/J/K/L** — scroll left/down/up/right in the frontmost app

Settings supports recording new global shortcuts, rejecting duplicates,
persisting changes, recovering from registration failures, and restoring
defaults. It has separate sections for shortcuts, scrolling, and cursor
control. Cursor-control tuning includes initial speed, maximum speed,
and acceleration so users can balance precise single-tap movement with fast
corner-to-corner travel. Movement keys such as **H/J/K/L** are configurable.
Mouse controls such as **Return**, double **Return**, **Shift-Return**,
**Control-Return**, and **hold Shift to drag** are fixed and are not exposed as
settings.

## Accessibility permission

Cursor Control requires Accessibility permission to synthesize keyboard-requested
input events: cursor movement, clicks, and universal scrolling. If access is
missing, Cursor Control explains why it is needed and can open the correct System
Settings pane.

Permission can be granted in **System Settings → Privacy & Security →
Accessibility**. Cursor Control checks the native event-posting permission whenever
the app becomes active and does not repeatedly show permission guidance for
every attempted click. It uses this access only to perform input explicitly
requested by the user.

If Cursor Control remains untrusted after it is enabled, remove the existing Cursor Control
entry with the minus button, reopen the current app, and grant access again.
This one-time reset may be necessary when replacing an older development build
that used a different local code-signing identity.

## Gatekeeper

GitHub Releases are ad-hoc signed and not Apple-notarized because Cursor Control
is distributed without an Apple Developer Program account. macOS may warn that
it cannot verify the developer. If you trust the downloaded release, allow it
from **System Settings → Privacy & Security**, or Control-click the app and
choose **Open** if that option is available.

Never bypass Gatekeeper for an app obtained from an untrusted source.

## Build from source

The build script is developer tooling only; downloaded releases do not ask users
to run it. It produces a normal `Cursor Control.app` bundle that can be opened
from Finder like any other macOS application.

Clone the repository, then run:

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/Cursor Control.app`, copies it
to Applications, and opens it. You can also build without launching:

```bash
swift build
```

## Roadmap

- [x] Phase 1 — AppKit menu bar foundation and repository setup
- [x] Cursor Control — Vim-style real cursor movement
- [x] Universal Scrolling — four-direction keyboard scrolling
- [x] Settings — shortcut, scroll, and cursor tuning
- [x] Onboarding — built-in quick-start guide
- [x] Release Preparation — zip packaging and Homebrew cask preparation

## GitHub Releases

Release artifacts are attached to tagged GitHub Releases. Maintainers can create
and verify a release package with:

```bash
VERSION=1.0.0 ./script/package_release.sh
VERSION=1.0.0 ./script/verify_release_package.sh
VERSION=1.0.0 ./script/generate_homebrew_cask.sh
```

See [RELEASING.md](RELEASING.md) for the full release checklist.

## Project structure

```text
Sources/CursorControl/
├── Accessibility/ Accessibility permission guidance
├── Application/   App lifecycle
├── CursorControl/ Vim-style real cursor movement
├── Keyboard/      Global shortcuts and key capture
├── MenuBar/       Status item and menu ownership
├── Mouse/         Native mouse clicking
├── Onboarding/    Built-in quick-start guide
├── Scroll/        Universal scroll event targeting and posting
├── Settings/      Settings window
└── Support/       Shared application constants
script/            Build and run tooling
packaging/         Generated Homebrew cask output
```

## Contributing

Issues and pull requests are welcome. Please keep changes focused, native to
macOS, and free from unnecessary dependencies.

## License

Cursor Control is available under the [MIT License](LICENSE).
