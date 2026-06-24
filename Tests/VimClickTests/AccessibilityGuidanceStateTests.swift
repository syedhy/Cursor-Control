import Testing
@testable import VimClick

struct AccessibilityGuidanceStateTests {
    @Test func missingPermissionGuidanceIsPresentedOnlyOncePerDeniedSession() {
        var state = AccessibilityGuidanceState()

        let firstAttempt = state.shouldPresentGuidance(isTrusted: false)
        let secondAttempt = state.shouldPresentGuidance(isTrusted: false)

        #expect(firstAttempt)
        #expect(!secondAttempt)
        #expect(state.hasPresentedGuidance)
    }

    @Test func grantingPermissionResetsGuidanceForAFutureRevocation() {
        var state = AccessibilityGuidanceState()
        _ = state.shouldPresentGuidance(isTrusted: false)

        state.refresh(isTrusted: true)
        let resetAfterGrant = !state.hasPresentedGuidance
        let revokedAgain = state.shouldPresentGuidance(isTrusted: false)

        #expect(resetAfterGrant)
        #expect(revokedAgain)
    }
}
