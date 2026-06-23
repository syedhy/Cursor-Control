import AppKit

struct ZoomState: Equatable {
    private(set) var path: [GridCoordinate] = []

    var depth: Int { path.count }

    mutating func reset() {
        path.removeAll(keepingCapacity: true)
    }

    @discardableResult
    mutating func zoom(
        into coordinate: GridCoordinate,
        coordinateSystem: GridCoordinateSystem,
        maxDepth: Int = AppConstants.maxZoomDepth
    ) -> Bool {
        guard depth < maxDepth, coordinateSystem.contains(coordinate) else {
            return false
        }

        path.append(coordinate)
        return true
    }

    func activeRegion(
        in bounds: NSRect,
        coordinateSystem: GridCoordinateSystem
    ) -> NSRect {
        path.reduce(bounds) { region, coordinate in
            coordinateSystem.cellFrame(for: coordinate, in: region)
        }
    }
}
