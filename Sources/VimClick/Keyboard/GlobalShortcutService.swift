import AppKit
import Carbon
import OSLog

private let vimClickHotKeySignature: OSType = 0x56434C4B // "VCLK"
private let activationHotKeyIdentifier: UInt32 = 1

private func globalShortcutEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ context: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event,
          let context,
          let hotKeyID = hotKeyID(from: event),
          hotKeyID.signature == vimClickHotKeySignature,
          hotKeyID.id == activationHotKeyIdentifier else {
        return OSStatus(eventNotHandledErr)
    }

    let service = Unmanaged<GlobalShortcutService>
        .fromOpaque(context)
        .takeUnretainedValue()
    Task { @MainActor [weak service] in
        service?.handleActivation()
    }
    return noErr
}

private func hotKeyID(from event: EventRef) -> EventHotKeyID? {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    return status == noErr ? hotKeyID : nil
}

@MainActor
final class GlobalShortcutService {
    private var eventHandler: EventHandlerRef?
    private var activationHotKey: EventHotKeyRef?
    private var onActivate: (() -> Void)?
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "GlobalShortcut"
    )

    @discardableResult
    func registerActivationShortcut(onActivate: @escaping @MainActor () -> Void) -> Bool {
        unregisterAll()
        self.onActivate = onActivate

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            globalShortcutEventHandler,
            1,
            &eventType,
            context,
            &eventHandler
        )
        guard handlerStatus == noErr else {
            logger.error("Could not install hotkey handler: \(handlerStatus)")
            unregisterAll()
            return false
        }

        let hotKeyID = EventHotKeyID(
            signature: vimClickHotKeySignature,
            id: activationHotKeyIdentifier
        )
        let registrationStatus = RegisterEventHotKey(
            KeyboardShortcuts.activationKeyCode,
            carbonModifiers(from: KeyboardShortcuts.activationModifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &activationHotKey
        )
        guard registrationStatus == noErr else {
            logger.error(
                "Could not register \(KeyboardShortcuts.activationDisplayName): \(registrationStatus)"
            )
            unregisterAll()
            return false
        }

        logger.notice("Registered \(KeyboardShortcuts.activationDisplayName)")
        return true
    }

    func unregisterAll() {
        if let activationHotKey {
            UnregisterEventHotKey(activationHotKey)
            self.activationHotKey = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        onActivate = nil
    }

    private func carbonModifiers(from modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    fileprivate func handleActivation() {
        logger.notice("Received \(KeyboardShortcuts.activationDisplayName)")
        onActivate?()
    }
}
