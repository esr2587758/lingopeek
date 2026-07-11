import AppKit
import Carbon.HIToolbox
import LingobarCore
import SwiftUI

@MainActor
final class LingobarHubWindowController {
    private let state = LingobarHubState()
    private var window: LingobarHubWindow?
    private let onRelaunch: (LingobarHubLibraryItem) -> Void

    init(onRelaunch: @escaping (LingobarHubLibraryItem) -> Void) {
        self.onRelaunch = onRelaunch
    }

    func show(
        section: LingobarHubSection = .collection,
        selectedCollectionID: UUID? = nil,
        selectedHistoryID: UUID? = nil
    ) {
        state.selectedSection = section
        if let selectedCollectionID {
            state.collectionQuery = ""
            state.collectionFilter = .all
            state.selectedCollectionID = selectedCollectionID
        }
        state.selectedHistoryID = selectedHistoryID
        state.refresh()
        let window = ensureWindow()
        window.setContentSize(LingobarHubWindow.hubSize)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
    }

    func close() {
        window?.orderOut(nil)
    }

    private func ensureWindow() -> LingobarHubWindow {
        if let window {
            return window
        }

        let window = LingobarHubWindow(
            contentRect: NSRect(origin: .zero, size: LingobarHubWindow.hubSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.title = "Lingobar Hub"
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.onCancel = { [weak self] in
            self?.close()
        }
        window.contentView = NSHostingView(
            rootView: LingobarHubView(
                state: state,
                onClose: { [weak self] in
                    self?.close()
                },
                onOpenAccessibility: { [weak self] in
                    Self.openAccessibilitySettings()
                    self?.state.refreshSettings()
                },
                onRelaunch: { [weak self] item in
                    self?.onRelaunch(item)
                }
            )
        )
        self.window = window
        return window
    }

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

private final class LingobarHubWindow: NSWindow {
    static let hubSize = NSSize(width: 920, height: 624)
    static let sidebarWidth: CGFloat = 188

    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == UInt16(kVK_Escape) {
            onCancel?()
            return
        }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown,
           event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            onCancel?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
