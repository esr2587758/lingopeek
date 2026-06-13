import Carbon.HIToolbox
import Foundation

final class HotKeyManager: @unchecked Sendable {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let onPressed: @MainActor @Sendable () -> Void

    init(onPressed: @escaping @MainActor @Sendable () -> Void) {
        self.onPressed = onPressed
    }

    func register() {
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
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

        let hotKeyID = EventHotKeyID(signature: fourCharCode("LPK1"), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
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
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { partial, character in
        (partial << 8) + OSType(character)
    }
}
