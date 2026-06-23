import AppKit

struct GridLayout {
    let rowCount: Int
    let columnCount: Int

    init(
        rowCount: Int = AppConstants.gridRows.count,
        columnCount: Int = AppConstants.gridColumns.count
    ) {
        precondition(rowCount > 0, "A grid must contain at least one row")
        precondition(columnCount > 0, "A grid must contain at least one column")

        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    func cellSize(in bounds: NSRect) -> NSSize {
        NSSize(
            width: bounds.width / CGFloat(columnCount),
            height: bounds.height / CGFloat(rowCount)
        )
    }
}
