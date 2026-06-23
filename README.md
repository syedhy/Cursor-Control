# VimClick

VimClick is an open-source, native macOS menu bar utility for clicking anywhere
on screen without taking your hands off the keyboard.

> [!NOTE]
> VimClick is under active development. The current codebase contains the
> Phase 4 keyboard-navigation foundation; clicking functionality is not
> available yet.

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

The build script is developer tooling; it is not part of the everyday user
experience. It produces a normal `VimClick.app` bundle that can be opened from
Finder like any other macOS application. Once launched, VimClick runs only in
the menu bar—there is no main window and no Dock icon.

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
- **Settings…** — opens the placeholder settings window
- **Quit VimClick** — exits the application

Press **Escape** to close the overlay.

Type a two-letter cell identifier to select it. The first character highlights
the matching row; the second highlights the exact cell and displays its center
point.

The selection begins at `aa`. Use **Control-H**, **Control-J**, **Control-K**,
and **Control-L** to move left, down, up, and right. Movement stops at grid
boundaries and supports normal macOS key repeat.

The planned default activation shortcut is **Command-Shift-Space**.

## Accessibility permission

VimClick will require Accessibility permission to synthesize mouse clicks.
That permission is not requested by the Phase 1 foundation because clicking is
not implemented yet.

Once implemented, permission can be granted in **System Settings → Privacy &
Security → Accessibility**. VimClick will use this access only to perform the
click explicitly requested by the user.

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
- [ ] Phase 5 — Recursive zoom system
- [ ] Phase 6 — Accessibility checks and mouse click simulation
- [ ] Phase 7 — Global activation shortcut
- [ ] Phase 8 — Settings and visual polish
- [ ] Phase 9 — DMG and GitHub Releases preparation

## GitHub Releases

Release artifacts will be attached to tagged GitHub Releases. DMG creation,
release checks, and maintainer instructions are scheduled for Phase 9.

## Project structure

```text
Sources/VimClick/
├── Application/   App lifecycle
├── Grid/          Grid layout and rendering
├── Keyboard/      Overlay keyboard input
├── MenuBar/       Status item and menu ownership
├── Overlay/       Screen detection and overlay window ownership
├── Selection/     Coordinate-selection state
├── Settings/      Settings window
└── Support/       Shared application constants
script/            Build and run tooling
```

## Contributing

Issues and pull requests are welcome. Please keep changes focused, native to
macOS, and free from unnecessary dependencies.

## License

VimClick is available under the [MIT License](LICENSE).
