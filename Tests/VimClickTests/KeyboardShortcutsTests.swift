import AppKit
import Testing
@testable import VimClick

@MainActor
struct KeyboardShortcutsTests {
    @Test func controlMovementCommandsAreCentralized() throws {
        #expect(KeyboardShortcuts.command(for: try event(character: "h", keyCode: 4)) == .moveLeft)
        #expect(KeyboardShortcuts.command(for: try event(character: "j", keyCode: 38)) == .moveDown)
        #expect(KeyboardShortcuts.command(for: try event(character: "k", keyCode: 40)) == .moveUp)
        #expect(KeyboardShortcuts.command(for: try event(character: "l", keyCode: 37)) == .moveRight)
    }

    @Test func repeatedMovementEventsUseTheSameCommandPath() throws {
        let repeatedEvent = try event(character: "l", keyCode: 37, isRepeat: true)
        #expect(repeatedEvent.isARepeat)
        #expect(KeyboardShortcuts.command(for: repeatedEvent) == .moveRight)
    }

    @Test func unmodifiedCharactersRemainAvailableForDirectSelection() throws {
        let event = try event(character: "C", keyCode: 8, modifiers: [.shift])
        #expect(KeyboardShortcuts.command(for: event) == .typeCharacter("c"))
    }

    @Test func spaceIsTheZoomCommandUnlessAConflictingModifierIsPressed() throws {
        let zoomEvent = try event(character: " ", keyCode: 49, modifiers: [])
        let commandSpace = try event(character: " ", keyCode: 49, modifiers: [.command])

        #expect(KeyboardShortcuts.command(for: zoomEvent) == .zoom)
        #expect(KeyboardShortcuts.command(for: commandSpace) == nil)
    }

    @Test func returnAndKeypadEnterPerformTheClick() throws {
        let returnEvent = try event(character: "\r", keyCode: 36, modifiers: [])
        let keypadEnterEvent = try event(character: "\r", keyCode: 76, modifiers: [.numericPad])

        #expect(KeyboardShortcuts.command(for: returnEvent) == .click)
        #expect(KeyboardShortcuts.command(for: keypadEnterEvent) == .click)
    }

    private func event(
        character: String,
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags = [.control],
        isRepeat: Bool = false
    ) throws -> NSEvent {
        try #require(
            NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: modifiers,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                characters: character,
                charactersIgnoringModifiers: character,
                isARepeat: isRepeat,
                keyCode: keyCode
            )
        )
    }
}
