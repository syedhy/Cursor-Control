import CoreGraphics

struct CursorMotion {
    static func unitVector(for heldDirections: Set<CursorMovementDirection>) -> CGVector {
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if heldDirections.contains(.left) { dx -= 1 }
        if heldDirections.contains(.right) { dx += 1 }
        if heldDirections.contains(.up) { dy -= 1 }
        if heldDirections.contains(.down) { dy += 1 }

        guard dx != 0 || dy != 0 else {
            return .zero
        }

        if dx != 0 && dy != 0 {
            let diagonalScale = 1 / sqrt(CGFloat(2))
            dx *= diagonalScale
            dy *= diagonalScale
        }

        return CGVector(dx: dx, dy: dy)
    }

    static func speed(forTick tick: Int, settings: CursorSettings = CursorSettings()) -> CGFloat {
        let accelerated = settings.initialSpeed
            + (Double(max(0, tick)) * settings.accelerationPerFrame)
        return CGFloat(min(accelerated, settings.maximumSpeed))
    }

    static func nextPoint(
        from point: CGPoint,
        heldDirections: Set<CursorMovementDirection>,
        tick: Int,
        bounds: CGRect,
        settings: CursorSettings = CursorSettings()
    ) -> CGPoint {
        let vector = unitVector(for: heldDirections)
        guard vector != .zero else {
            return point
        }

        let speed = speed(forTick: tick, settings: settings)
        return clamp(
            CGPoint(
                x: point.x + (vector.dx * speed),
                y: point.y + (vector.dy * speed)
            ),
            to: bounds
        )
    }

    static func clamp(_ point: CGPoint, to bounds: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX - 1),
            y: min(max(point.y, bounds.minY), bounds.maxY - 1)
        )
    }
}
