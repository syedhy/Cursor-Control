import AppKit

@MainActor
final class CursorModeIndicatorController {
    private var window: NSWindow?
    private var updateTimer: Timer?
    private var trailPoints: [CGPoint] = []

    func show() {
        let overlayFrame = Self.overlayFrame()

        if window == nil {
            window = makeWindow(frame: overlayFrame)
        } else {
            window?.setFrame(overlayFrame, display: false)
        }

        trailPoints.removeAll()
        updatePosition()
        window?.orderFrontRegardless()
        startTimer()
    }

    func hide() {
        stopTimer()
        trailPoints.removeAll()
        window?.orderOut(nil)
    }

    func update(toQuartzCursorLocation cursorLocation: CGPoint) {
        appendIndicatorPoint(
            for: Self.appKitScreenPoint(fromQuartzGlobalPoint: cursorLocation)
                ?? NSEvent.mouseLocation
        )
    }

    private func makeWindow(frame: CGRect) -> NSWindow {
        let window = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        window.contentView = CursorModeIndicatorView(
            frame: CGRect(origin: .zero, size: frame.size)
        )
        return window
    }

    private func startTimer() {
        guard updateTimer == nil else { return }

        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 1 / AppConstants.cursorModeIndicatorFrameRate,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePosition()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updatePosition() {
        guard let window else { return }

        let overlayFrame = Self.overlayFrame()
        if window.frame != overlayFrame {
            window.setFrame(overlayFrame, display: false)
            window.contentView?.frame = CGRect(origin: .zero, size: overlayFrame.size)
        }

        appendIndicatorPoint(for: NSEvent.mouseLocation)
    }

    private func appendIndicatorPoint(for cursorLocation: CGPoint) {
        guard let window else { return }

        let indicatorCenter = CGPoint(
            x: cursorLocation.x + AppConstants.cursorModeIndicatorOffsetX,
            y: cursorLocation.y + AppConstants.cursorModeIndicatorOffsetY
        )
        trailPoints.append(indicatorCenter)
        if trailPoints.count > AppConstants.cursorModeIndicatorTrailLength {
            trailPoints.removeFirst(trailPoints.count - AppConstants.cursorModeIndicatorTrailLength)
        }

        if let indicatorView = window.contentView as? CursorModeIndicatorView {
            let windowOrigin = window.frame.origin
            indicatorView.trailPoints = trailPoints.map {
                CGPoint(x: $0.x - windowOrigin.x, y: $0.y - windowOrigin.y)
            }
        }
    }

    private static func overlayFrame() -> CGRect {
        let screenFrames = NSScreen.screens.map(\.frame)
        guard var frame = screenFrames.first else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        for screenFrame in screenFrames.dropFirst() {
            frame = frame.union(screenFrame)
        }

        return frame
    }

    private static func appKitScreenPoint(fromQuartzGlobalPoint quartzPoint: CGPoint) -> CGPoint? {
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }

            let quartzBounds = CGDisplayBounds(CGDirectDisplayID(screenNumber.uint32Value))
            guard quartzBounds.insetBy(dx: -1, dy: -1).contains(quartzPoint) else {
                continue
            }

            return CGPoint(
                x: screen.frame.minX + (quartzPoint.x - quartzBounds.minX),
                y: screen.frame.maxY - (quartzPoint.y - quartzBounds.minY)
            )
        }

        return nil
    }
}

private final class CursorModeIndicatorView: NSView {
    var trailPoints: [CGPoint] = [] {
        didSet {
            needsDisplay = true
        }
    }

    override var isOpaque: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard !trailPoints.isEmpty else { return }

        drawTrail()
        drawCurrentDot()
    }

    private func drawTrail() {
        let cappedTailPoints = cappedTailPoints()
        guard cappedTailPoints.count > 1 else { return }

        for index in 1 ..< cappedTailPoints.count {
            let progress = CGFloat(index) / CGFloat(cappedTailPoints.count - 1)
            let previousPoint = cappedTailPoints[index - 1]
            let currentPoint = cappedTailPoints[index]

            drawTrailSegment(
                from: previousPoint,
                to: currentPoint,
                lineWidth: AppConstants.cursorModeIndicatorHaloSize * 0.82,
                alpha: 0.045 * pow(progress, 1.55)
            )
            drawTrailSegment(
                from: previousPoint,
                to: currentPoint,
                lineWidth: AppConstants.cursorModeIndicatorDotSize * 1.8,
                alpha: 0.13 * pow(progress, 1.75)
            )
        }
    }

    private func cappedTailPoints() -> [CGPoint] {
        guard let currentPoint = trailPoints.last else { return [] }
        guard trailPoints.count > 1 else { return [currentPoint] }

        var cappedPoints = [currentPoint]
        var remainingLength = AppConstants.cursorModeIndicatorTrailMaxLength

        for index in stride(from: trailPoints.count - 2, through: 0, by: -1) {
            let previousPoint = trailPoints[index]
            guard let newestTailPoint = cappedPoints.first else { break }
            let segmentLength = previousPoint.distance(to: newestTailPoint)

            guard segmentLength > 0 else { continue }

            if segmentLength <= remainingLength {
                cappedPoints.insert(previousPoint, at: 0)
                remainingLength -= segmentLength
            } else {
                let progress = remainingLength / segmentLength
                cappedPoints.insert(
                    newestTailPoint.interpolated(toward: previousPoint, progress: progress),
                    at: 0
                )
                break
            }
        }

        return cappedPoints
    }

    private func drawTrailSegment(from startPoint: CGPoint, to endPoint: CGPoint, lineWidth: CGFloat, alpha: CGFloat) {
        let segment = NSBezierPath()
        segment.move(to: startPoint)
        segment.line(to: endPoint)
        segment.lineCapStyle = .round
        segment.lineJoinStyle = .round

        NSColor.systemBlue.withAlphaComponent(alpha).setStroke()
        segment.lineWidth = lineWidth
        segment.stroke()
    }

    private func drawCurrentDot() {
        guard let currentPoint = trailPoints.last else { return }

        let haloSize = AppConstants.cursorModeIndicatorHaloSize
        NSColor.systemBlue.withAlphaComponent(0.18).setFill()
        NSBezierPath(
            ovalIn: CGRect(
                x: currentPoint.x - haloSize / 2,
                y: currentPoint.y - haloSize / 2,
                width: haloSize,
                height: haloSize
            )
        ).fill()

        let dotSize = AppConstants.cursorModeIndicatorDotSize
        NSColor.systemBlue.withAlphaComponent(0.88).setFill()
        NSBezierPath(
            ovalIn: CGRect(
                x: currentPoint.x - dotSize / 2,
                y: currentPoint.y - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
        ).fill()
    }
}

private extension CGPoint {
    func distance(to otherPoint: CGPoint) -> CGFloat {
        let deltaX = x - otherPoint.x
        let deltaY = y - otherPoint.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    func interpolated(toward otherPoint: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (otherPoint.x - x) * progress,
            y: y + (otherPoint.y - y) * progress
        )
    }
}
