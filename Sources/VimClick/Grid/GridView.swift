import AppKit

@MainActor
final class GridView: NSView {
    private let coordinateSystem: GridCoordinateSystem
    private let precisionCoordinateSystem: GridCoordinateSystem
    private var selection = SelectionState()
    private var zoom = ZoomState()

    init(
        coordinateSystem: GridCoordinateSystem = GridCoordinateSystem(),
        precisionCoordinateSystem: GridCoordinateSystem = GridCoordinateSystem(
            rowIdentifiers: AppConstants.precisionGridRows,
            columnIdentifiers: AppConstants.precisionGridColumns
        )
    ) {
        self.coordinateSystem = coordinateSystem
        self.precisionCoordinateSystem = precisionCoordinateSystem
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    func update(selection: SelectionState, zoom: ZoomState) {
        self.selection = selection
        self.zoom = zoom
        needsDisplay = true
    }

    func selectedPoint() -> NSPoint? {
        guard case .cell(let coordinate) = selection.highlight else { return nil }

        let activeRegion = zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem)
        return activeCoordinateSystem.center(of: coordinate, in: activeRegion)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let activeRegion = zoom.activeRegion(in: bounds, coordinateSystem: coordinateSystem)
        drawBackground()
        drawActiveRegion(activeRegion)
        drawSelectionHighlight(in: activeRegion)
        drawGrid(in: activeRegion)
        drawLabels(in: activeRegion)
        drawCenterDot()
    }

    private func drawBackground() {
        NSColor.windowBackgroundColor
            .withAlphaComponent(AppConstants.overlayBackgroundOpacity)
            .setFill()
        bounds.fill()
    }

    private func drawActiveRegion(_ activeRegion: NSRect) {
        guard zoom.depth > 0 else { return }

        NSColor.controlAccentColor.withAlphaComponent(0.08).setFill()
        activeRegion.fill()

        let border = NSBezierPath(rect: activeRegion)
        border.lineWidth = 1.5
        NSColor.controlAccentColor.withAlphaComponent(0.80).setStroke()
        border.stroke()
    }

    private func drawSelectionHighlight(in activeRegion: NSRect) {
        let highlightFrame: NSRect
        let opacity: CGFloat

        switch selection.highlight {
        case .none:
            return
        case .row(let row):
            highlightFrame = activeCoordinateSystem.rowFrame(at: row, in: activeRegion)
            opacity = 0.12
        case .cell(let coordinate):
            highlightFrame = activeCoordinateSystem.cellFrame(for: coordinate, in: activeRegion)
            opacity = 0.26
        }

        NSColor.controlAccentColor.withAlphaComponent(opacity).setFill()
        highlightFrame.fill()
    }

    private func drawGrid(in activeRegion: NSRect) {
        let coordinateSystem = activeCoordinateSystem
        let cellSize = coordinateSystem.cellSize(in: activeRegion)
        let path = NSBezierPath()
        path.lineWidth = AppConstants.gridLineWidth

        for column in 0...coordinateSystem.columnCount {
            let x = activeRegion.minX + (CGFloat(column) * cellSize.width)
            path.move(to: NSPoint(x: x, y: activeRegion.minY))
            path.line(to: NSPoint(x: x, y: activeRegion.maxY))
        }

        for row in 0...coordinateSystem.rowCount {
            let y = activeRegion.minY + (CGFloat(row) * cellSize.height)
            path.move(to: NSPoint(x: activeRegion.minX, y: y))
            path.line(to: NSPoint(x: activeRegion.maxX, y: y))
        }

        NSColor.labelColor
            .withAlphaComponent(AppConstants.gridLineOpacity)
            .setStroke()
        path.stroke()
    }

    private func drawLabels(in activeRegion: NSRect) {
        let coordinateSystem = activeCoordinateSystem
        let cellSize = coordinateSystem.cellSize(in: activeRegion)
        guard cellSize.width >= 20, cellSize.height >= 14 else { return }

        let fontSize = min(13, max(9, min(cellSize.width, cellSize.height) * 0.20))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.78)
        ]

        for row in 0..<coordinateSystem.rowCount {
            for column in 0..<coordinateSystem.columnCount {
                let coordinate = GridCoordinate(row: row, column: column)
                let label = coordinateSystem.identifier(for: coordinate) as NSString
                let labelSize = label.size(withAttributes: attributes)
                let cellFrame = coordinateSystem.cellFrame(for: coordinate, in: activeRegion)
                let origin = NSPoint(
                    x: cellFrame.midX - (labelSize.width / 2),
                    y: cellFrame.midY - (labelSize.height / 2)
                )

                label.draw(at: origin, withAttributes: attributes)
            }
        }
    }

    private func drawCenterDot() {
        guard let center = selectedPoint() else { return }
        let dotDiameter: CGFloat = 7
        let dotRect = NSRect(
            x: center.x - (dotDiameter / 2),
            y: center.y - (dotDiameter / 2),
            width: dotDiameter,
            height: dotDiameter
        )

        NSColor.controlAccentColor.setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    private var activeCoordinateSystem: GridCoordinateSystem {
        zoom.depth == 0 ? coordinateSystem : precisionCoordinateSystem
    }
}
