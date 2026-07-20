import Carbon.HIToolbox
import Foundation

final class HotKeyManager: @unchecked Sendable {
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var callbacks: [UInt32: @MainActor @Sendable () -> Void] = [:]
    private var handlerRef: EventHandlerRef?
    private let signature = fourCharCode("LPK1")

    @discardableResult
    func register(
        _ hotKey: LingobarHotKey,
        id: UInt32,
        onPressed: @escaping @MainActor @Sendable () -> Void
    ) -> OSStatus {
        let handlerStatus = installHandlerIfNeeded()
        guard handlerStatus == noErr else {
            return handlerStatus
        }

        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        var nextHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &nextHotKeyRef
        )
        if status != noErr {
            return status
        }

        if let existing = hotKeyRefs[id] {
            UnregisterEventHotKey(existing)
        }
        hotKeyRefs[id] = nextHotKeyRef
        callbacks[id] = onPressed
        return status
    }

    func unregister() {
        for hotKeyRef in hotKeyRefs.values {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs = [:]
        callbacks = [:]
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private func installHandlerIfNeeded() -> OSStatus {
        guard handlerRef == nil else {
            return noErr
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        return InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return noErr
                }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                guard let callback = manager.callback(for: event) else {
                    return noErr
                }
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        callback()
                    }
                }
                return noErr
            },
            1,
            &eventSpec,
            userData,
            &handlerRef
        )
    }

    private func callback(for event: EventRef?) -> (@MainActor @Sendable () -> Void)? {
        guard let event else {
            return nil
        }
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
        guard status == noErr,
              hotKeyID.signature == signature else {
            return nil
        }
        return callbacks[hotKeyID.id]
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { partial, character in
        (partial << 8) + OSType(character)
    }
}
