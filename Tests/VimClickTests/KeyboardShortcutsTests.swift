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

    @Test func precisionModeUsesPlainVimMovementKeys() throws {
        let plainLeft = try event(character: "h", keyCode: 4, modifiers: [])
        let plainDown = try event(character: "j", keyCode: 38, modifiers: [])
        let plainUp = try event(character: "k", keyCode: 40, modifiers: [])
        let plainRight = try event(character: "l", keyCode: 37, modifiers: [], isRepeat: true)

        #expect(KeyboardShortcuts.command(for: plainLeft, mode: .precision) == .moveLeft)
        #expect(KeyboardShortcuts.command(for: plainDown, mode: .precision) == .moveDown)
        #expect(KeyboardShortcuts.command(for: plainUp, mode: .precision) == .moveUp)
        #expect(KeyboardShortcuts.command(for: plainRight, mode: .precision) == .moveRight)
    }

    @Test func precisionModeConsumesUnavailableSelectionAndZoomCommands() throws {
        let typedIdentifier = try event(character: "c", keyCode: 8, modifiers: [])
        let controlMovement = try event(character: "j", keyCode: 38, modifiers: [.control])
        let secondZoom = try event(character: " ", keyCode: 49, modifiers: [])

        #expect(KeyboardShortcuts.command(for: typedIdentifier, mode: .precision) == .ignore)
        #expect(KeyboardShortcuts.command(for: controlMovement, mode: .precision) == .ignore)
        #expect(KeyboardShortcuts.command(for: secondZoom, mode: .precision) == .ignore)
    }

    @Test func activationShortcutHasTheExpectedDefault() {
        #expect(KeyboardShortcuts.activationKeyCode == 49)
        #expect(KeyboardShortcuts.activationModifiers == [.command, .shift])
        #expect(KeyboardShortcuts.activationKeyEquivalent == " ")
        #expect(KeyboardShortcuts.activationDisplayName == "Command-Shift-Space")
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
