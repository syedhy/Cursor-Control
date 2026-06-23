import AppKit
import Testing
@testable import VimClick

struct ZoomStateTests {
    private let coordinateSystem = GridCoordinateSystem()
    private let bounds = NSRect(x: 0, y: 0, width: 260, height: 170)

    @Test func zoomPathProducesAnExactNestedActiveRegion() {
        var zoom = ZoomState()

        let firstZoomSucceeded = zoom.zoom(
            into: GridCoordinate(row: 2, column: 10),
            coordinateSystem: coordinateSystem
        )
        #expect(firstZoomSucceeded)
        #expect(zoom.depth == 1)
        #expect(zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem) == NSRect(
            x: 100,
            y: 20,
            width: 10,
            height: 10
        ))
        #expect(!zoom.allowsDirectSelection)
    }

    @Test func maxDepthIsEnforcedAndFurtherZoomIsIgnored() {
        var zoom = ZoomState()

        for _ in 0..<AppConstants.maxZoomDepth {
            let zoomSucceeded = zoom.zoom(into: .first, coordinateSystem: coordinateSystem)
            #expect(zoomSucceeded)
        }

        let regionAtMaxDepth = zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem)
        let extraZoomSucceeded = zoom.zoom(into: .first, coordinateSystem: coordinateSystem)
        #expect(!extraZoomSucceeded)
        #expect(zoom.depth == AppConstants.maxZoomDepth)
        #expect(zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem) == regionAtMaxDepth)
    }

    @Test func resetRestoresTheFullOverlayRegion() {
        var zoom = ZoomState()
        zoom.zoom(into: GridCoordinate(row: 5, column: 12), coordinateSystem: coordinateSystem)

        zoom.reset()

        #expect(zoom.depth == 0)
        #expect(zoom.allowsDirectSelection)
        #expect(zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem) == bounds)
    }
}
