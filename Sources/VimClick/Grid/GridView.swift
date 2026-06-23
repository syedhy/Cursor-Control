import AppKit

@MainActor
final class GridView: NSView {
    private let layout: GridLayout

    init(layout: GridLayout = GridLayout()) {
        self.layout = layout
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawGrid()
    }

    private func drawBackground() {
        NSColor.windowBackgroundColor
            .withAlphaComponent(AppConstants.overlayBackgroundOpacity)
            .setFill()
        bounds.fill()
    }

    private func drawGrid() {
        let cellSize = layout.cellSize(in: bounds)
        let path = NSBezierPath()
        path.lineWidth = AppConstants.gridLineWidth

        for column in 0...layout.columnCount {
            let x = bounds.minX + (CGFloat(column) * cellSize.width)
            path.move(to: NSPoint(x: x, y: bounds.minY))
            path.line(to: NSPoint(x: x, y: bounds.maxY))
        }

        for row in 0...layout.rowCount {
            let y = bounds.minY + (CGFloat(row) * cellSize.height)
            path.move(to: NSPoint(x: bounds.minX, y: y))
            path.line(to: NSPoint(x: bounds.maxX, y: y))
        }

        NSColor.labelColor
            .withAlphaComponent(AppConstants.gridLineOpacity)
            .setStroke()
        path.stroke()
    }
}
