import CoreGraphics
import Testing
@testable import VimClick

struct CursorMotionTests {
    @Test func oppositeDirectionsCancelOut() {
        let vector = CursorMotion.unitVector(for: [.left, .right])

        #expect(vector == .zero)
    }

    @Test func diagonalMovementIsNormalized() {
        let vector = CursorMotion.unitVector(for: [.up, .right])

        #expect(abs(vector.dx - 0.707) < 0.001)
        #expect(abs(vector.dy + 0.707) < 0.001)
    }

    @Test func speedAcceleratesButCaps() {
        let settings = CursorSettings(
            initialSpeed: 2,
            maximumSpeed: 6,
            accelerationPerFrame: 1,
            frameRate: 60
        )

        #expect(CursorMotion.speed(forTick: 0, settings: settings) == 2)
        #expect(CursorMotion.speed(forTick: 10_000, settings: settings) == 6)
    }

    @Test func cursorSettingsClampAndKeepMaximumAtLeastInitialSpeed() {
        let settings = CursorSettings(
            initialSpeed: 20,
            maximumSpeed: 2,
            accelerationPerFrame: 99,
            frameRate: 1_000
        )

        #expect(settings.initialSpeed == 20)
        #expect(settings.maximumSpeed == 20)
        #expect(settings.accelerationPerFrame == CursorSettings.maximumAccelerationPerFrame)
        #expect(settings.frameRate == CursorSettings.maximumFrameRate)
    }

    @Test func nextPointUsesCustomCursorSettings() {
        let settings = CursorSettings(
            initialSpeed: 1,
            maximumSpeed: 10,
            accelerationPerFrame: 2,
            frameRate: 60
        )

        let point = CursorMotion.nextPoint(
            from: CGPoint(x: 10, y: 10),
            heldDirections: [.right],
            tick: 2,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            settings: settings
        )

        #expect(point == CGPoint(x: 15, y: 10))
    }

    @Test func pointIsClampedToDisplayBounds() {
        let point = CursorMotion.clamp(
            CGPoint(x: -100, y: 2000),
            to: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )

        #expect(point == CGPoint(x: 0, y: 799))
    }
}
