import AppKit

struct GridCoordinate: Equatable, Hashable {
    let row: Int
    let column: Int

    static let first = GridCoordinate(row: 0, column: 0)
}

struct GridCoordinateSystem {
    let rowIdentifiers: [Character]
    let columnIdentifiers: [Character]

    init(
        rowIdentifiers: [Character] = AppConstants.gridRows,
        columnIdentifiers: [Character] = AppConstants.gridColumns
    ) {
        precondition(!rowIdentifiers.isEmpty, "A grid must contain at least one row")
        precondition(!columnIdentifiers.isEmpty, "A grid must contain at least one column")
        precondition(Set(rowIdentifiers).count == rowIdentifiers.count, "Row identifiers must be unique")
        precondition(Set(columnIdentifiers).count == columnIdentifiers.count, "Column identifiers must be unique")

        self.rowIdentifiers = rowIdentifiers
        self.columnIdentifiers = columnIdentifiers
    }

    var rowCount: Int { rowIdentifiers.count }
    var columnCount: Int { columnIdentifiers.count }

    func rowIndex(for identifier: Character) -> Int? {
        rowIdentifiers.firstIndex(of: identifier)
    }

    func columnIndex(for identifier: Character) -> Int? {
        columnIdentifiers.firstIndex(of: identifier)
    }

    func identifier(for coordinate: GridCoordinate) -> String {
        guard contains(coordinate) else { return "" }
        return String(rowIdentifiers[coordinate.row]) + String(columnIdentifiers[coordinate.column])
    }

    func contains(_ coordinate: GridCoordinate) -> Bool {
        (0..<rowCount).contains(coordinate.row)
            && (0..<columnCount).contains(coordinate.column)
    }

    func cellSize(in bounds: NSRect) -> NSSize {
        NSSize(
            width: bounds.width / CGFloat(columnCount),
            height: bounds.height / CGFloat(rowCount)
        )
    }

    func cellFrame(for coordinate: GridCoordinate, in bounds: NSRect) -> NSRect {
        guard contains(coordinate) else { return .zero }

        let size = cellSize(in: bounds)
        return NSRect(
            x: bounds.minX + (CGFloat(coordinate.column) * size.width),
            y: bounds.minY + (CGFloat(coordinate.row) * size.height),
            width: size.width,
            height: size.height
        )
    }

    func rowFrame(at row: Int, in bounds: NSRect) -> NSRect {
        guard (0..<rowCount).contains(row) else { return .zero }

        let cellHeight = cellSize(in: bounds).height
        return NSRect(
            x: bounds.minX,
            y: bounds.minY + (CGFloat(row) * cellHeight),
            width: bounds.width,
            height: cellHeight
        )
    }

    func center(of coordinate: GridCoordinate, in bounds: NSRect) -> NSPoint {
        let frame = cellFrame(for: coordinate, in: bounds)
        return NSPoint(x: frame.midX, y: frame.midY)
    }
}
