import Testing
@testable import VimClick

struct SelectionStateTests {
    private let coordinateSystem = GridCoordinateSystem()

    @Test func typingRowThenColumnSelectsTheExpectedCell() {
        var selection = SelectionState()

        let handledRow = selection.handleCharacter("c", coordinateSystem: coordinateSystem)
        #expect(handledRow)
        #expect(selection.highlight == .row(2))

        let handledColumn = selection.handleCharacter("k", coordinateSystem: coordinateSystem)
        #expect(handledColumn)
        #expect(selection.coordinate == GridCoordinate(row: 2, column: 10))
        #expect(selection.highlight == .cell(GridCoordinate(row: 2, column: 10)))
    }

    @Test func completedSelectionAcceptsANewRowIdentifier() {
        var selection = SelectionState()
        selection.handleCharacter("c", coordinateSystem: coordinateSystem)
        selection.handleCharacter("k", coordinateSystem: coordinateSystem)

        let handledNewRow = selection.handleCharacter("l", coordinateSystem: coordinateSystem)
        #expect(handledNewRow)
        #expect(selection.coordinate == GridCoordinate(row: 11, column: 0))
        #expect(selection.highlight == .row(11))
    }

    @Test func invalidRowInputIsIgnoredAndResetClearsProgress() {
        var selection = SelectionState()

        let handledInvalidRow = selection.handleCharacter("z", coordinateSystem: coordinateSystem)
        #expect(!handledInvalidRow)
        #expect(selection.highlight == .none)

        selection.handleCharacter("c", coordinateSystem: coordinateSystem)
        selection.reset()
        #expect(selection.coordinate == .first)
        #expect(selection.highlight == .none)
    }
}
