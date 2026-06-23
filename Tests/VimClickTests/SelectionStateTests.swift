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
        #expect(selection.highlight == .cell(.first))

        selection.handleCharacter("c", coordinateSystem: coordinateSystem)
        selection.reset()
        #expect(selection.coordinate == .first)
        #expect(selection.highlight == .cell(.first))
    }

    @Test func movementStartsAtAAAndStopsAtEveryBoundary() {
        var selection = SelectionState()

        #expect(selection.highlight == .cell(.first))
        let movedPastTop = selection.move(rowDelta: -1, columnDelta: 0, coordinateSystem: coordinateSystem)
        let movedPastLeft = selection.move(rowDelta: 0, columnDelta: -1, coordinateSystem: coordinateSystem)
        #expect(!movedPastTop)
        #expect(!movedPastLeft)

        for _ in 0..<40 {
            selection.move(rowDelta: 0, columnDelta: 1, coordinateSystem: coordinateSystem)
        }
        #expect(selection.coordinate == GridCoordinate(row: 0, column: 25))

        for _ in 0..<20 {
            selection.move(rowDelta: 1, columnDelta: 0, coordinateSystem: coordinateSystem)
        }
        #expect(selection.coordinate == GridCoordinate(row: 16, column: 25))
        let movedPastBottom = selection.move(rowDelta: 1, columnDelta: 0, coordinateSystem: coordinateSystem)
        let movedPastRight = selection.move(rowDelta: 0, columnDelta: 1, coordinateSystem: coordinateSystem)
        #expect(!movedPastBottom)
        #expect(!movedPastRight)
    }

    @Test func movementCompletesAPartialTypedRowSelection() {
        var selection = SelectionState()
        selection.handleCharacter("c", coordinateSystem: coordinateSystem)

        #expect(selection.highlight == .row(2))
        let moved = selection.move(rowDelta: 0, columnDelta: 1, coordinateSystem: coordinateSystem)
        #expect(moved)
        #expect(selection.coordinate == GridCoordinate(row: 2, column: 1))
        #expect(selection.highlight == .cell(GridCoordinate(row: 2, column: 1)))
    }
}
