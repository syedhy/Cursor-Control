import AppKit
import OSLog

@MainActor
final class ScrollService {
    private let permissionService: any AccessibilityPermissionProviding
    private let permissionAlert: any AccessibilityPermissionAlerting
    private let targetProvider: any ScrollTargetProviding
    private let eventPoster: any ScrollEventPosting
    private let settingsProvider: () -> ScrollSettings
    private var accessibilityGuidanceState = AccessibilityGuidanceState()
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "Scroll"
    )

    init(
        permissionService: any AccessibilityPermissionProviding = AccessibilityPermissionService(),
        permissionAlert: any AccessibilityPermissionAlerting = AccessibilityPermissionAlert(),
        targetProvider: any ScrollTargetProviding = FrontmostScrollTargetProvider(),
        eventPoster: any ScrollEventPosting = QuartzScrollEventPoster(),
        settingsProvider: @escaping () -> ScrollSettings = { ScrollSettings() }
    ) {
        self.permissionService = permissionService
        self.permissionAlert = permissionAlert
        self.targetProvider = targetProvider
        self.eventPoster = eventPoster
        self.settingsProvider = settingsProvider
    }

    func refreshAccessibilityPermission() {
        accessibilityGuidanceState.refresh(isTrusted: permissionService.isTrusted)
    }

    func scroll(
        _ direction: ScrollDirection,
        isInteractionActive: Bool,
        repeatCount: Int = 0
    ) {
        guard !isInteractionActive else { return }

        let isTrusted = permissionService.isTrusted
        guard isTrusted else {
            if accessibilityGuidanceState.shouldPresentGuidance(isTrusted: isTrusted),
               permissionAlert.presentMissingPermission() {
                permissionService.requestSystemPrompt()
                permissionService.openSystemSettings()
            }
            return
        }

        accessibilityGuidanceState.refresh(isTrusted: true)

        let settings = settingsProvider()
        let pixelDelta = settings.effectivePixelDelta(
            for: direction,
            repeatCount: repeatCount
        )
        for _ in 0..<settings.eventsPerShortcut {
            let request = direction.eventRequest(
                screenLocation: targetProvider.scrollLocation,
                pixelDelta: pixelDelta
            )
            if eventPoster.postScrollEvent(request) {
                logger.notice("Posted scroll event")
            }
        }
    }
}
