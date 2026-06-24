import AppKit
import Testing
@testable import VimClick

struct GridCoordinateSystemTests {
    private let coordinateSystem = GridCoordinateSystem()

    @Test func defaultGridUsesConfiguredDimensionsAndIdentifiers() {
        #expect(coordinateSystem.rowCount == 17)
        #expect(coordinateSystem.columnCount == 26)
        #expect(coordinateSystem.identifier(for: .first) == "aa")
        #expect(coordinateSystem.identifier(for: GridCoordinate(row: 16, column: 25)) == "qz")
    }

    @Test func precisionGridIsSquareAndHasAnExactCenterCell() {
        let precisionCoordinateSystem = GridCoordinateSystem(
            rowIdentifiers: AppConstants.precisionGridRows,
            columnIdentifiers: AppConstants.precisionGridColumns
        )

        #expect(precisionCoordinateSystem.rowCount == 25)
        #expect(precisionCoordinateSystem.columnCount == 25)
        #expect(precisionCoordinateSystem.centerCoordinate == GridCoordinate(row: 12, column: 12))
    }

    @Test func cellGeometryUsesTheSameCenterAsRendering() {
        let bounds = NSRect(x: 0, y: 0, width: 260, height: 170)
        let coordinate = GridCoordinate(row: 2, column: 10)

        #expect(coordinateSystem.cellFrame(for: coordinate, in: bounds) == NSRect(x: 100, y: 20, width: 10, height: 10))
        #expect(coordinateSystem.center(of: coordinate, in: bounds) == NSPoint(x: 105, y: 25))
    }

    @Test func configuredGridProducesNearSquareCellsOnTheCapturedDisplay() {
        let capturedDisplayBounds = NSRect(x: 0, y: 0, width: 1976, height: 1280)
        let cellSize = coordinateSystem.cellSize(in: capturedDisplayBounds)

        #expect(cellSize.width == cellSize.height)
    }

    @Test func gridCoversTheDisplayWithSquareCellsWhenRatiosDoNotMatch() {
        let bounds = NSRect(x: 10, y: 20, width: 300, height: 170)
        let gridFrame = coordinateSystem.gridFrame(in: bounds)
        let cellSize = coordinateSystem.cellSize(in: bounds)

        #expect(cellSize.width == cellSize.height)
        #expect(gridFrame.midX == bounds.midX)
        #expect(gridFrame.midY == bounds.midY)
        #expect(gridFrame.width >= bounds.width)
        #expect(gridFrame.height >= bounds.height)
        #expect(gridFrame.minX <= bounds.minX)
        #expect(gridFrame.maxX >= bounds.maxX)
        #expect(gridFrame.minY <= bounds.minY)
        #expect(gridFrame.maxY >= bounds.maxY)
    }
}
