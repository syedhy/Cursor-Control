import CoreGraphics

protocol ScrollEventPosting {
    func postScrollEvent(_ request: ScrollEventRequest) -> Bool
}

struct QuartzScrollEventPoster: ScrollEventPosting {
    func postScrollEvent(_ request: ScrollEventRequest) -> Bool {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        guard let event = CGEvent(
            scrollWheelEvent2Source: eventSource,
            units: .pixel,
            wheelCount: 2,
            wheel1: request.verticalDelta,
            wheel2: request.horizontalDelta,
            wheel3: 0
        ) else {
            return false
        }

        event.location = request.screenLocation
        event.post(tap: .cghidEventTap)
        return true
    }
}
