import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

struct SelectionReader {
    func selectedTextIncludingClipboardFallback() -> String? {
        if Self.uiTestSelectionFilePath != nil {
            return selectedText()
        }
        guard Self.canReadSelection else {
            return nil
        }
        if let selectedText = selectedText() {
            return selectedText
        }
        if selectedTextRangeLength() == 0 {
            return nil
        }
        return selectedTextByCopyingSelection()
    }

    func selectedText() -> String? {
        if let path = Self.uiTestSelectionFilePath {
            let selected = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            let trimmed = selected?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        guard Self.canReadSelection else {
            return nil
        }
        guard let focusedElement else {
            return nil
        }

        var selectedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &selectedValue) == .success,
              let selected = selectedValue as? String else {
            return nil
        }

        let trimmed = selected.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static var canReadSelection: Bool {
        AXIsProcessTrusted()
    }

    private static var uiTestSelectionFilePath: String? {
        let environment = ProcessInfo.processInfo.environment
        guard environment["LINGOPEEK_UI_TEST_MODE"] == "1",
              let path = environment["LINGOPEEK_UI_TEST_SELECTION_FILE"],
              !path.isEmpty else {
            return nil
        }
        return path
    }

    private var focusedElement: AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focusedValue) == .success,
              let focused = focusedValue,
              CFGetTypeID(focused) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(focused, to: AXUIElement.self)
    }

    private func selectedTextRangeLength() -> Int? {
        guard Self.canReadSelection else {
            return nil
        }
        guard let focusedElement else {
            return nil
        }

        var rangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success,
              let rangeValue,
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }

        let rangeAXValue = unsafeDowncast(rangeValue, to: AXValue.self)
        var range = CFRange()
        guard AXValueGetValue(rangeAXValue, .cfRange, &range) else {
            return nil
        }
        return range.length
    }

    private func selectedTextByCopyingSelection() -> String? {
        guard Self.canReadSelection else {
            return nil
        }
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard: pasteboard)
        let oldChangeCount = pasteboard.changeCount

        sendCopyShortcut()
        let deadline = Date().addingTimeInterval(0.22)
        while pasteboard.changeCount == oldChangeCount, Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        guard pasteboard.changeCount != oldChangeCount else {
            return nil
        }

        let copiedText = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        snapshot.restore(to: pasteboard)

        guard let copiedText, !copiedText.isEmpty else {
            return nil
        }
        return copiedText
    }

    private func sendCopyShortcut() {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

private struct PasteboardSnapshot {
    private struct Item {
        var values: [(type: NSPasteboard.PasteboardType, data: Data)]
    }

    private var items: [Item] = []

    init(pasteboard: NSPasteboard) {
        items = pasteboard.pasteboardItems?.map { item in
            Item(values: item.types.compactMap { type in
                guard let data = item.data(forType: type) else {
                    return nil
                }
                return (type, data)
            })
        } ?? []
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let restoredItems = items.map { snapshotItem in
            let item = NSPasteboardItem()
            snapshotItem.values.forEach { value in
                item.setData(value.data, forType: value.type)
            }
            return item
        }
        if !restoredItems.isEmpty {
            pasteboard.writeObjects(restoredItems)
        }
    }
}
