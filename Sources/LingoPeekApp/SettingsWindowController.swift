import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        let window = ensureWindow()
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func ensureWindow() -> NSWindow {
        if let window {
            return window
        }

        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 680),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "Lingobar Settings"
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.contentView = NSHostingView(rootView: SettingsView())
        self.window = window
        return window
    }
}

private final class SettingsWindow: NSWindow {
    private let sidebarWidth: CGFloat = 212
    private let mainHeaderHeight: CGFloat = 78
    private let sidebarHeaderHeight: CGFloat = 58

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, shouldDragWindow(for: event) {
            performDrag(with: event)
            return
        }
        super.sendEvent(event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            orderOut(nil)
            return
        }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            orderOut(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private func shouldDragWindow(for event: NSEvent) -> Bool {
        let point = event.locationInWindow
        let height = frame.height
        let isMainHeader = point.x >= sidebarWidth && point.y >= height - mainHeaderHeight
        let isSidebarHeader = point.x < sidebarWidth && point.y >= height - sidebarHeaderHeight
        return isMainHeader || isSidebarHeader
    }
}
