# VimClick

VimClick is an open-source, native macOS menu bar utility for clicking anywhere
on screen without taking your hands off the keyboard.

> [!NOTE]
> VimClick is under active development. The current codebase contains the
> Phase 8 keyboard-driven clicking foundation, including global shortcut
> configuration, centered precision zoom, and a native settings window.

## Goals

- Native AppKit interface with no web runtime
- Fast, keyboard-first interaction
- Lightweight menu bar presence
- Clear, maintainable architecture
- Straightforward GitHub Releases distribution

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later, or the matching Xcode Command Line Tools
- Swift 6 compatible toolchain

## Build from source

The build script is developer tooling only; downloaded releases will not ask
users to run it. It produces a normal `VimClick.app` bundle that can be opened
from Finder like any other macOS application. Once built, that app can be
reopened directly without rerunning the script. VimClick runs only in the menu
bar—there is no main window and no Dock icon.

Clone the repository, then run:

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/VimClick.app`, and opens it.
You can also build without launching:

```bash
swift build
```

## Installation

A downloadable DMG will be published through GitHub Releases once release
packaging is complete. The intended installation flow is:

1. Download `VimClick.dmg` from the repository's Releases page.
2. Open the DMG.
3. Drag VimClick into Applications.
4. Open VimClick from Applications.
5. Grant Accessibility access when prompted.

During development, `./script/build_and_run.sh` creates a local app bundle in
`dist/` instead. That app bundle runs independently after it has been built;
the script only needs to be run again when rebuilding the source.

## Usage

Opening `VimClick.app` adds a cursor icon to the macOS menu bar. It does not
open a main application window or appear in the Dock. The current build provides:

- **Activate VimClick** — opens a grid overlay on the display containing the cursor
- **Settings…** — opens shortcut preferences
- **Quit VimClick** — exits the application

Press **Escape** to close the overlay.

Type a two-letter cell identifier to select it. The first character highlights
the matching row; the second highlights the exact cell and displays its center
point.

The selection begins at `aa`. Use **Control-H**, **Control-J**, **Control-K**,
and **Control-L** to move left, down, up, and right. Movement stops at grid
boundaries and supports normal macOS key repeat.

Press **Space** once to zoom into the selected cell. VimClick draws a square
25-by-25 precision grid inside that cell and starts at its exact center. In this
precision view, direct cell identifiers, Control-modified movement, and further
zooming are disabled; use plain **H/J/K/L** to position the center point before
clicking.

Press **Return** to perform a left click at the center dot and close the
overlay.

The default global shortcuts are:

- **Command-Shift-Space** — activate the overlay
- **Command-Shift-Option-R** — reserved for cursor-control mode
- **Command-Control-H/J/K/L** — reserved for left/down/up/right scrolling

Settings supports recording new global shortcuts, rejecting duplicates,
persisting changes, recovering from registration failures, and restoring
defaults. Mode-local keys such as **H/J/K/L**, **Space**, **Return**, and
**Escape** are fixed and are not exposed as settings.

## Accessibility permission

VimClick requires Accessibility permission only to synthesize the left click
requested when you press Return. If access is missing, VimClick explains why it
is needed and can open the correct System Settings pane.

Permission can be granted in **System Settings → Privacy & Security →
Accessibility**. VimClick checks the native event-posting permission whenever
the app becomes active and does not repeatedly show permission guidance for
every attempted click. It uses this access only to perform input explicitly
requested by the user.

If VimClick remains untrusted after it is enabled, remove the existing VimClick
entry with the minus button, reopen the current app, and grant access again.
This one-time reset may be necessary when replacing an older development build
that used a different local code-signing identity.

## Gatekeeper

Early GitHub Releases may be unsigned because building VimClick does not
require Apple Developer Program membership. macOS may warn that it cannot
verify the developer. If you trust the downloaded release, Control-click the
app and choose **Open**, or allow it from **System Settings → Privacy & Security**.

Never bypass Gatekeeper for an app obtained from an untrusted source.

## Screenshots

_Screenshots will be added as the overlay interface is implemented._

## Demo GIF

_A keyboard-driven usage demo will be added before the first release._

## Roadmap

- [x] Phase 1 — AppKit menu bar foundation and repository setup
- [x] Phase 2 — Fullscreen overlay and grid rendering
- [x] Phase 3 — Coordinate selection and center-point state
- [x] Phase 4 — Vim-style navigation with key repeat
- [x] Phase 5 — Recursive zoom system
- [x] Phase 6 — Accessibility checks and mouse click simulation
- [x] Phase 7 — Reliability, global activation, and centered precision zoom
- [x] Phase 8 — Settings and configurable shortcut architecture
- [ ] Phase 9 — Universal four-direction scrolling
- [ ] Phase 10 — Vim cursor-control mode
- [ ] Phase 11 — DMG and GitHub Releases preparation

## GitHub Releases

Release artifacts will be attached to tagged GitHub Releases. DMG creation,
release checks, and maintainer instructions are scheduled for Phase 11 after
scrolling and cursor-control mode are complete.

## Project structure

```text
Sources/VimClick/
├── Accessibility/ Accessibility permission guidance
├── Application/   App lifecycle
├── Grid/          Grid layout and rendering
├── Keyboard/      Global shortcuts and overlay keyboard input
├── MenuBar/       Status item and menu ownership
├── Mouse/         Coordinate conversion and native clicking
├── Overlay/       Screen detection and overlay window ownership
├── Selection/     Coordinate-selection state
├── Settings/      Settings window
├── Support/       Shared application constants
└── Zoom/          Recursive precision state
script/            Build and run tooling
```

## Contributing

Issues and pull requests are welcome. Please keep changes focused, native to
macOS, and free from unnecessary dependencies.

## License

VimClick is available under the [MIT License](LICENSE).
