import AppKit
import Testing
@testable import VimClick

@MainActor
struct GridViewTests {
    private let coordinateSystem = GridCoordinateSystem()

    @Test func clickPointUsesTheSameCellCenterAsTheVisibleDot() throws {
        let view = GridView(coordinateSystem: coordinateSystem)
        view.frame = NSRect(x: 0, y: 0, width: 260, height: 170)
        var selection = SelectionState()
        selection.handleCharacter("c", coordinateSystem: coordinateSystem)
        selection.handleCharacter("j", coordinateSystem: coordinateSystem)

        view.update(selection: selection, zoom: ZoomState())

        #expect(try #require(view.selectedPoint()) == NSPoint(x: 95, y: 25))
    }

    @Test func zoomedClickPointUsesTheNestedVisibleCenter() throws {
        let view = GridView(coordinateSystem: coordinateSystem)
        view.frame = NSRect(x: 0, y: 0, width: 260, height: 170)
        var zoom = ZoomState()
        zoom.zoom(into: GridCoordinate(row: 2, column: 9), coordinateSystem: coordinateSystem)
        let selection = SelectionState()

        view.update(selection: selection, zoom: zoom)

        let point = try #require(view.selectedPoint())
        #expect(abs(point.x - (90 + (5.0 / 26.0))) < 0.0001)
        #expect(abs(point.y - (20 + (5.0 / 17.0))) < 0.0001)
    }
}
