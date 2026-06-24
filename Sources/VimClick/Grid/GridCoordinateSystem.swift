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
    var centerCoordinate: GridCoordinate {
        GridCoordinate(row: rowCount / 2, column: columnCount / 2)
    }

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

    func gridFrame(in bounds: NSRect) -> NSRect {
        // Fill the entire display while preserving square cells. A small amount
        // may extend beyond one pair of edges when the aspect ratios differ.
        let side = max(
            bounds.width / CGFloat(columnCount),
            bounds.height / CGFloat(rowCount)
        )
        let size = NSSize(
            width: side * CGFloat(columnCount),
            height: side * CGFloat(rowCount)
        )

        return NSRect(
            x: bounds.midX - (size.width / 2),
            y: bounds.midY - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

    func cellSize(in bounds: NSRect) -> NSSize {
        let gridFrame = gridFrame(in: bounds)
        let side = gridFrame.width / CGFloat(columnCount)
        return NSSize(width: side, height: side)
    }

    func cellFrame(for coordinate: GridCoordinate, in bounds: NSRect) -> NSRect {
        guard contains(coordinate) else { return .zero }

        let gridFrame = gridFrame(in: bounds)
        let size = cellSize(in: bounds)
        return NSRect(
            x: gridFrame.minX + (CGFloat(coordinate.column) * size.width),
            y: gridFrame.minY + (CGFloat(coordinate.row) * size.height),
            width: size.width,
            height: size.height
        )
    }

    func rowFrame(at row: Int, in bounds: NSRect) -> NSRect {
        guard (0..<rowCount).contains(row) else { return .zero }

        let gridFrame = gridFrame(in: bounds)
        let cellHeight = cellSize(in: bounds).height
        return NSRect(
            x: gridFrame.minX,
            y: gridFrame.minY + (CGFloat(row) * cellHeight),
            width: gridFrame.width,
            height: cellHeight
        )
    }

    func center(of coordinate: GridCoordinate, in bounds: NSRect) -> NSPoint {
        let frame = cellFrame(for: coordinate, in: bounds)
        return NSPoint(x: frame.midX, y: frame.midY)
    }
}
