import Carbon.HIToolbox
import Foundation

final class HotKeyManager: @unchecked Sendable {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var nextHotKeyID: UInt32 = 1
    private let onPressed: @MainActor @Sendable () -> Void

    init(onPressed: @escaping @MainActor @Sendable () -> Void) {
        self.onPressed = onPressed
    }

    @discardableResult
    func register(_ hotKey: LingobarHotKey = AppSettings.hotKey) -> OSStatus {
        let handlerStatus = installHandlerIfNeeded()
        guard handlerStatus == noErr else {
            return handlerStatus
        }

        let hotKeyID = EventHotKeyID(signature: fourCharCode("LPK1"), id: nextHotKeyID)
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

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nextHotKeyRef
        nextHotKeyID = nextHotKeyID &+ 1
        return status
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
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
            { _, _, userData in
                guard let userData else {
                    return noErr
                }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        manager.onPressed()
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
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { partial, character in
        (partial << 8) + OSType(character)
    }
}
