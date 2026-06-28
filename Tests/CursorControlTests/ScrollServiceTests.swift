import CoreGraphics
import Testing
@testable import CursorControl

@MainActor
struct ScrollServiceTests {
    private let testLocation = CGPoint(x: 320, y: 240)

    @Test func directionsMapToQuartzScrollDeltas() {
        #expect(
            ScrollDirection.up.eventRequest(screenLocation: testLocation)
                == ScrollEventRequest(
                    verticalDelta: AppConstants.defaultScrollPixelDelta,
                    horizontalDelta: 0,
                    screenLocation: testLocation
                )
        )
        #expect(
            ScrollDirection.down.eventRequest(screenLocation: testLocation)
                == ScrollEventRequest(
                    verticalDelta: -AppConstants.defaultScrollPixelDelta,
                    horizontalDelta: 0,
                    screenLocation: testLocation
                )
        )
        #expect(
            ScrollDirection.left.eventRequest(screenLocation: testLocation)
                == ScrollEventRequest(
                    verticalDelta: 0,
                    horizontalDelta: AppConstants.defaultScrollPixelDelta,
                    screenLocation: testLocation
                )
        )
        #expect(
            ScrollDirection.right.eventRequest(screenLocation: testLocation)
                == ScrollEventRequest(
                    verticalDelta: 0,
                    horizontalDelta: -AppConstants.defaultScrollPixelDelta,
                    screenLocation: testLocation
                )
        )
    }

    @Test func scrollPostsAtTargetLocation() {
        let poster = SpyScrollEventPoster()
        let service = makeService(
            targetProvider: FakeScrollTargetProvider(scrollLocation: testLocation),
            eventPoster: poster
        )

        service.scroll(.down, isInteractionActive: false)

        #expect(
            poster.requests == Array(
                repeating: ScrollDirection.down.eventRequest(screenLocation: testLocation),
                count: AppConstants.defaultScrollEventsPerShortcut
            )
        )
    }

    @Test func scrollSettingsControlDistanceAndEventsPerShortcut() {
        let poster = SpyScrollEventPoster()
        let settings = ScrollSettings(
            pixelDelta: 640,
            eventsPerShortcut: 3,
            accelerationPerRepeat: 0,
            verticalMultiplier: 1,
            horizontalMultiplier: 1
        )
        let service = makeService(
            targetProvider: FakeScrollTargetProvider(scrollLocation: testLocation),
            eventPoster: poster,
            settingsProvider: { settings }
        )

        service.scroll(.down, isInteractionActive: false)

        #expect(
            poster.requests == Array(
                repeating: ScrollDirection.down.eventRequest(
                    screenLocation: testLocation,
                    pixelDelta: 640
                ),
                count: 3
            )
        )
    }

    @Test func scrollSettingsClampExtremeValues() {
        let settings = ScrollSettings(
            pixelDelta: 10_000,
            eventsPerShortcut: 99,
            accelerationPerRepeat: 99,
            maximumAccelerationMultiplier: 99,
            verticalMultiplier: 99,
            horizontalMultiplier: 99
        )

        #expect(settings.pixelDelta == ScrollSettings.maximumPixelDelta)
        #expect(settings.eventsPerShortcut == ScrollSettings.maximumEventsPerShortcut)
        #expect(settings.accelerationPerRepeat == ScrollSettings.maximumAccelerationPerRepeat)
        #expect(settings.maximumAccelerationMultiplier == ScrollSettings.maximumMaximumMultiplier)
        #expect(settings.verticalMultiplier == ScrollSettings.maximumAxisMultiplier)
        #expect(settings.horizontalMultiplier == ScrollSettings.maximumAxisMultiplier)
    }

    @Test func scrollSettingsAllowOnePixelPrecision() {
        let settings = ScrollSettings(pixelDelta: 1)

        #expect(settings.pixelDelta == 1)
    }

    @Test func scrollAccelerationUsesRepeatCountAndCaps() {
        let settings = ScrollSettings(
            pixelDelta: 100,
            accelerationPerRepeat: 0.5,
            maximumAccelerationMultiplier: 2,
            verticalMultiplier: 1,
            horizontalMultiplier: 1
        )

        #expect(settings.effectivePixelDelta(for: .down, repeatCount: 0) == 100)
        #expect(settings.effectivePixelDelta(for: .down, repeatCount: 1) == 150)
        #expect(settings.effectivePixelDelta(for: .down, repeatCount: 99) == 200)
    }

    @Test func scrollAxisMultipliersCanDiffer() {
        let settings = ScrollSettings(
            pixelDelta: 100,
            verticalMultiplier: 2,
            horizontalMultiplier: 0.5
        )

        #expect(settings.effectivePixelDelta(for: .up, repeatCount: 0) == 200)
        #expect(settings.effectivePixelDelta(for: .right, repeatCount: 0) == 50)
    }

    @Test func scrollIsIgnoredWhileAnotherCursorControlInteractionIsActive() {
        let poster = SpyScrollEventPoster()
        let service = makeService(eventPoster: poster)

        service.scroll(.right, isInteractionActive: true)

        #expect(poster.requests.isEmpty)
    }

    @Test func missingPermissionShowsGuidanceOnlyOncePerDeniedSession() {
        let permission = FakeAccessibilityPermission(isTrusted: false)
        let alert = FakeAccessibilityAlert(shouldOpenSettings: true)
        let poster = SpyScrollEventPoster()
        let service = makeService(
            permission: permission,
            alert: alert,
            eventPoster: poster
        )

        service.scroll(.down, isInteractionActive: false)
        service.scroll(.down, isInteractionActive: false)

        #expect(poster.requests.isEmpty)
        #expect(alert.missingPermissionCount == 1)
        #expect(permission.requestPromptCount == 1)
        #expect(permission.openSettingsCount == 1)
    }

    @Test func failedScrollEventCreationDoesNotCrashOrPrompt() {
        let alert = FakeAccessibilityAlert()
        let poster = SpyScrollEventPoster(shouldSucceed: false)
        let service = makeService(alert: alert, eventPoster: poster)

        service.scroll(.left, isInteractionActive: false)

        #expect(poster.requests.count == AppConstants.defaultScrollEventsPerShortcut)
        #expect(alert.missingPermissionCount == 0)
    }

    private func makeService(
        permission: FakeAccessibilityPermission = FakeAccessibilityPermission(isTrusted: true),
        alert: FakeAccessibilityAlert = FakeAccessibilityAlert(),
        targetProvider: FakeScrollTargetProvider = FakeScrollTargetProvider(
            scrollLocation: CGPoint(x: 100, y: 100)
        ),
        eventPoster: SpyScrollEventPoster = SpyScrollEventPoster(),
        settingsProvider: @escaping () -> ScrollSettings = { ScrollSettings() }
    ) -> ScrollService {
        ScrollService(
            permissionService: permission,
            permissionAlert: alert,
            targetProvider: targetProvider,
            eventPoster: eventPoster,
            settingsProvider: settingsProvider
        )
    }
}

private final class FakeAccessibilityPermission: AccessibilityPermissionProviding {
    var isTrusted: Bool
    private(set) var requestPromptCount = 0
    private(set) var openSettingsCount = 0

    init(isTrusted: Bool) {
        self.isTrusted = isTrusted
    }

    func requestSystemPrompt() {
        requestPromptCount += 1
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}

@MainActor
private final class FakeAccessibilityAlert: AccessibilityPermissionAlerting {
    private let shouldOpenSettings: Bool
    private(set) var missingPermissionCount = 0
    private(set) var clickFailureCount = 0

    init(shouldOpenSettings: Bool = false) {
        self.shouldOpenSettings = shouldOpenSettings
    }

    func presentMissingPermission() -> Bool {
        missingPermissionCount += 1
        return shouldOpenSettings
    }

    func presentClickFailure() {
        clickFailureCount += 1
    }
}

private struct FakeScrollTargetProvider: ScrollTargetProviding {
    let scrollLocation: CGPoint
}

private final class SpyScrollEventPoster: ScrollEventPosting {
    let shouldSucceed: Bool
    private(set) var requests: [ScrollEventRequest] = []

    init(shouldSucceed: Bool = true) {
        self.shouldSucceed = shouldSucceed
    }

    func postScrollEvent(_ request: ScrollEventRequest) -> Bool {
        requests.append(request)
        return shouldSucceed
    }
}
