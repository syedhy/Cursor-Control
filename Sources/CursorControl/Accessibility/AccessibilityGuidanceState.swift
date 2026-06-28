struct AccessibilityGuidanceState {
    private(set) var hasPresentedGuidance = false

    mutating func refresh(isTrusted: Bool) {
        if isTrusted {
            hasPresentedGuidance = false
        }
    }

    mutating func shouldPresentGuidance(isTrusted: Bool) -> Bool {
        refresh(isTrusted: isTrusted)

        guard !isTrusted, !hasPresentedGuidance else {
            return false
        }

        hasPresentedGuidance = true
        return true
    }
}
