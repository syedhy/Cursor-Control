import AppKit
import Testing
@testable import VimClick

struct GridCoordinateSystemTests {
    private let coordinateSystem = GridCoordinateSystem()

    @Test func defaultGridUsesConfiguredDimensionsAndIdentifiers() {
        #expect(coordinateSystem.rowCount == 12)
        #expect(coordinateSystem.columnCount == 26)
        #expect(coordinateSystem.identifier(for: .first) == "aa")
        #expect(coordinateSystem.identifier(for: GridCoordinate(row: 11, column: 25)) == "lz")
    }

    @Test func cellGeometryUsesTheSameCenterAsRendering() {
        let bounds = NSRect(x: 0, y: 0, width: 260, height: 120)
        let coordinate = GridCoordinate(row: 2, column: 10)

        #expect(coordinateSystem.cellFrame(for: coordinate, in: bounds) == NSRect(x: 100, y: 20, width: 10, height: 10))
        #expect(coordinateSystem.center(of: coordinate, in: bounds) == NSPoint(x: 105, y: 25))
    }
}
