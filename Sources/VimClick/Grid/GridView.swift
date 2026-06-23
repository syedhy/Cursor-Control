import AppKit

@MainActor
final class GridView: NSView {
    private let coordinateSystem: GridCoordinateSystem
    private var selection = SelectionState()

    init(coordinateSystem: GridCoordinateSystem = GridCoordinateSystem()) {
        self.coordinateSystem = coordinateSystem
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    func update(selection: SelectionState) {
        self.selection = selection
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawSelectionHighlight()
        drawGrid()
        drawLabels()
        drawCenterDot()
    }

    private func drawBackground() {
        NSColor.windowBackgroundColor
            .withAlphaComponent(AppConstants.overlayBackgroundOpacity)
            .setFill()
        bounds.fill()
    }

    private func drawSelectionHighlight() {
        let highlightFrame: NSRect
        let opacity: CGFloat

        switch selection.highlight {
        case .none:
            return
        case .row(let row):
            highlightFrame = coordinateSystem.rowFrame(at: row, in: bounds)
            opacity = 0.12
        case .cell(let coordinate):
            highlightFrame = coordinateSystem.cellFrame(for: coordinate, in: bounds)
            opacity = 0.26
        }

        NSColor.controlAccentColor.withAlphaComponent(opacity).setFill()
        highlightFrame.fill()
    }

    private func drawGrid() {
        let cellSize = coordinateSystem.cellSize(in: bounds)
        let path = NSBezierPath()
        path.lineWidth = AppConstants.gridLineWidth

        for column in 0...coordinateSystem.columnCount {
            let x = bounds.minX + (CGFloat(column) * cellSize.width)
            path.move(to: NSPoint(x: x, y: bounds.minY))
            path.line(to: NSPoint(x: x, y: bounds.maxY))
        }

        for row in 0...coordinateSystem.rowCount {
            let y = bounds.minY + (CGFloat(row) * cellSize.height)
            path.move(to: NSPoint(x: bounds.minX, y: y))
            path.line(to: NSPoint(x: bounds.maxX, y: y))
        }

        NSColor.labelColor
            .withAlphaComponent(AppConstants.gridLineOpacity)
            .setStroke()
        path.stroke()
    }

    private func drawLabels() {
        let cellSize = coordinateSystem.cellSize(in: bounds)
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
                let cellFrame = coordinateSystem.cellFrame(for: coordinate, in: bounds)
                let origin = NSPoint(
                    x: cellFrame.midX - (labelSize.width / 2),
                    y: cellFrame.midY - (labelSize.height / 2)
                )

                label.draw(at: origin, withAttributes: attributes)
            }
        }
    }

    private func drawCenterDot() {
        guard case .cell(let coordinate) = selection.highlight else { return }

        let center = coordinateSystem.center(of: coordinate, in: bounds)
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
}
