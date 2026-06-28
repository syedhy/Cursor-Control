# Cursor Control

Cursor Control is an open-source, native macOS menu bar utility for controlling the
mouse cursor and scrolling with the keyboard.

> [!NOTE]
> Cursor Control is under active development. The current app is focused on two core
> features: Vim-style cursor control and universal scrolling.

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

## Build from source

The build script is developer tooling only; downloaded releases will not ask
users to run it. It produces a normal `Cursor Control.app` bundle that can be opened
from Finder like any other macOS application. Once built, that app can be
reopened directly without rerunning the script. Cursor Control runs only in the menu
bar—there is no main window and no Dock icon.

Clone the repository, then run:

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/Cursor Control.app`, and opens it.
You can also build without launching:

```bash
swift build
```

## Installation

A downloadable DMG will be published through GitHub Releases once release
packaging is complete. The intended installation flow is:

1. Download `Cursor Control.dmg` from the repository's Releases page.
2. Open the DMG.
3. Drag Cursor Control into Applications.
4. Open Cursor Control from Applications.
5. Grant Accessibility access when prompted.

During development, `./script/build_and_run.sh` creates a local app bundle in
`dist/` instead. That app bundle runs independently after it has been built;
the script only needs to be run again when rebuilding the source.

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

Early GitHub Releases may be unsigned because building Cursor Control does not
require Apple Developer Program membership. macOS may warn that it cannot
verify the developer. If you trust the downloaded release, Control-click the
app and choose **Open**, or allow it from **System Settings → Privacy & Security**.

Never bypass Gatekeeper for an app obtained from an untrusted source.

## Screenshots

_Screenshots will be added before the first release._

## Demo GIF

_A keyboard-driven usage demo will be added before the first release._

## Roadmap

- [x] Phase 1 — AppKit menu bar foundation and repository setup
- [x] Cursor Control — Vim-style real cursor movement
- [x] Universal Scrolling — four-direction keyboard scrolling
- [x] Settings — shortcut, scroll, and cursor tuning
- [x] Onboarding — built-in quick-start guide
- [ ] Release Preparation — DMG and GitHub Releases preparation

## GitHub Releases

Release artifacts will be attached to tagged GitHub Releases. DMG creation,
release checks, and maintainer instructions are scheduled after cursor control,
scrolling, settings, and onboarding are complete.

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
```

## Contributing

Issues and pull requests are welcome. Please keep changes focused, native to
macOS, and free from unnecessary dependencies.

## License

Cursor Control is available under the [MIT License](LICENSE).
