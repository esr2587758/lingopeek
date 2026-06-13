import AppKit
import SwiftUI

@MainActor
final class LingobarController {
    private let viewModel = LingobarViewModel()
    private let selectionReader = SelectionReader()
    private let settingsWindowController = SettingsWindowController()
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?

    func start() {
        installStatusItem()
        hotKeyManager = HotKeyManager { [weak self] in
            Task { @MainActor in
                self?.presentFromHotKey()
            }
        }
        hotKeyManager?.register()
        present(captureSelectionByCopying: false)
    }

    func stop() {
        hotKeyManager?.unregister()
    }

    func toggle() {
        guard let panel else {
            present()
            return
        }
        panel.isVisible ? hide() : present()
    }

    func present() {
        present(captureSelectionByCopying: true)
    }

    private func presentFromHotKey() {
        present(captureSelectionByCopying: true)
    }

    private func present(captureSelectionByCopying: Bool) {
        let selection = captureSelectionByCopying
            ? selectionReader.selectedTextIncludingClipboardFallback()
            : selectionReader.selectedText()
        viewModel.present(selection: selection)
        let panel = ensurePanel()
        position(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "L"
        item.button?.toolTip = "Lingobar"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Lingobar", action: #selector(showFromMenu), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Hide", action: #selector(hideFromMenu), keyEquivalent: "w"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LingoPeek", action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 386),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.title = "Lingobar"
        panel.contentView = NSHostingView(rootView: LingobarRootView(viewModel: viewModel))
        panel.orderFrontRegardless()
        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let mouse = NSEvent.mouseLocation
        let x = min(max(mouse.x - 170, visibleFrame.minX + 24), visibleFrame.maxX - panel.frame.width - 24)
        let y = min(max(mouse.y - 64, visibleFrame.minY + 24), visibleFrame.maxY - panel.frame.height - 24)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    @objc private func showFromMenu() {
        present()
    }

    @objc private func hideFromMenu() {
        hide()
    }

    @objc private func showSettingsFromMenu() {
        settingsWindowController.show()
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }
}
