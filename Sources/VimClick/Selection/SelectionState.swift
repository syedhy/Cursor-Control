struct SelectionState: Equatable {
    enum Highlight: Equatable {
        case none
        case row(Int)
        case cell(GridCoordinate)
    }

    private(set) var coordinate: GridCoordinate = .first
    private(set) var highlight: Highlight = .none

    mutating func reset() {
        coordinate = .first
        highlight = .none
    }

    @discardableResult
    mutating func handleCharacter(
        _ character: Character,
        coordinateSystem: GridCoordinateSystem
    ) -> Bool {
        if case .row(let row) = highlight,
           let column = coordinateSystem.columnIndex(for: character) {
            coordinate = GridCoordinate(row: row, column: column)
            highlight = .cell(coordinate)
            return true
        }

        guard let row = coordinateSystem.rowIndex(for: character) else {
            return false
        }

        coordinate = GridCoordinate(row: row, column: 0)
        highlight = .row(row)
        return true
    }
}
