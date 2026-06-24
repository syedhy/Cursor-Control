struct SelectionState: Equatable {
    enum Highlight: Equatable {
        case none
        case row(Int)
        case cell(GridCoordinate)
    }

    private(set) var coordinate: GridCoordinate = .first
    private(set) var highlight: Highlight = .cell(.first)

    mutating func reset(to coordinate: GridCoordinate = .first) {
        self.coordinate = coordinate
        highlight = .cell(coordinate)
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

    @discardableResult
    mutating func move(
        rowDelta: Int,
        columnDelta: Int,
        coordinateSystem: GridCoordinateSystem
    ) -> Bool {
        let destination = GridCoordinate(
            row: min(max(coordinate.row + rowDelta, 0), coordinateSystem.rowCount - 1),
            column: min(max(coordinate.column + columnDelta, 0), coordinateSystem.columnCount - 1)
        )

        guard destination != coordinate || highlight != .cell(coordinate) else {
            return false
        }

        coordinate = destination
        highlight = .cell(destination)
        return true
    }
}
