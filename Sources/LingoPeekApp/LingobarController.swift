import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class LingobarController: NSObject, NSWindowDelegate {
    private static let setupPanelSize = NSSize(width: 720, height: 360)
    private static let selectionPanelSize = NSSize(width: 720, height: 532)
    private static let selectionLoadingPanelSize = NSSize(width: 720, height: 441)
    private static let inputEmptyPanelSize = NSSize(width: 720, height: 72)
    private static let inputLoadingPanelSize = NSSize(width: 720, height: 287)
    private static let inputResultPanelSize = NSSize(width: 720, height: 377)
    private static let savedPanelOriginXKey = "Lingobar.savedPanelOriginX"
    private static let savedPanelOriginYKey = "Lingobar.savedPanelOriginY"

    private let viewModel: LingobarViewModel
    private let selectionReader = SelectionReader()
    private let settingsWindowController = SettingsWindowController()
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var settingsObserver: NSObjectProtocol?
    private var registeredHotKey: LingobarHotKey?
    private var isPositioningProgrammatically = false

    override init() {
        let viewModel = LingobarViewModel()
        self.viewModel = viewModel
        super.init()
        viewModel.onLayoutChanged = { [weak self] in
            self?.resizePanelForCurrentState()
        }
    }

    func start() {
        installStatusItem()
        hotKeyManager = HotKeyManager { [weak self] in
            Task { @MainActor in
                self?.presentFromHotKey()
            }
        }
        registerConfiguredHotKey()
        settingsObserver = NotificationCenter.default.addObserver(
            forName: AppSettings.hotKeyDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.registerConfiguredHotKey()
            }
        }
        present(captureSelectionByCopying: false)
    }

    func stop() {
        hotKeyManager?.unregister()
        registeredHotKey = nil
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
            self.settingsObserver = nil
        }
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

    private func registerConfiguredHotKey() {
        let hotKey = AppSettings.hotKey
        guard hotKey != registeredHotKey else {
            return
        }
        let status = hotKeyManager?.register(hotKey) ?? noErr
        if status == noErr {
            registeredHotKey = hotKey
        } else if let registeredHotKey {
            AppSettings.saveHotKey(registeredHotKey)
        }
    }

    private func present(captureSelectionByCopying: Bool) {
        let setupGateStatus = AppSettings.setupGateStatus
        guard setupGateStatus.requiredAction == .useLingobar else {
            viewModel.presentSetupGate(setupGateStatus)
            let panel = ensurePanel()
            panel.setContentSize(contentSize)
            position(panel)
            show(panel)
            return
        }

        let sourceAppName = frontmostSourceAppName()
        let selection = captureSelectionByCopying
            ? selectionReader.selectedTextIncludingClipboardFallback()
            : selectionReader.selectedText()
        viewModel.present(selection: selection, sourceAppName: sourceAppName)
        let panel = ensurePanel()
        panel.setContentSize(contentSize)
        position(panel)
        show(panel)
    }

    private func show(_ panel: NSPanel) {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeMain()
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

        let panel = LingobarPanel(
            contentRect: NSRect(origin: .zero, size: Self.selectionPanelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.onCancel = { [weak self] in
            self?.hide()
        }
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.title = "Lingobar"
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: LingobarRootView(
                viewModel: viewModel,
                onClose: { [weak self] in
                    self?.hide()
                },
                onOpenSettings: { [weak self] in
                    self?.settingsWindowController.show()
                },
                onOpenAccessibility: {
                    Self.openAccessibilitySettings()
                }
            )
        )
        panel.orderFrontRegardless()
        self.panel = panel
        return panel
    }

    private var contentSize: NSSize {
        switch viewModel.mode {
        case .setup:
            Self.setupPanelSize
        case .selection:
            viewModel.isLoading ? Self.selectionLoadingPanelSize : Self.selectionPanelSize
        case .input:
            if viewModel.isLoading {
                Self.inputLoadingPanelSize
            } else {
                viewModel.showsResult ? Self.inputResultPanelSize : Self.inputEmptyPanelSize
            }
        }
    }

    private func resizePanelForCurrentState() {
        guard let panel else {
            return
        }
        updatePanelProgrammatically {
            panel.setContentSize(contentSize)
        }
        let origin = clampedOrigin(panel.frame.origin, size: panel.frame.size, in: placementVisibleFrame(for: panel.frame.origin))
        if origin != panel.frame.origin {
            updatePanelProgrammatically {
                panel.setFrameOrigin(origin)
            }
        }
        if savedPanelOrigin() != nil {
            savePanelPosition(panel.frame.origin)
        }
    }

    private func frontmostSourceAppName() -> String {
        let appName = NSWorkspace.shared.frontmostApplication?.localizedName
        guard let appName, appName != "LingoPeek" else {
            return "当前 App"
        }
        return appName
    }

    private func position(_ panel: NSPanel) {
        let visibleFrame = placementVisibleFrame(for: savedPanelOrigin() ?? NSEvent.mouseLocation)
        let origin = savedPanelOrigin()
            ?? centeredOrigin(size: panel.frame.size, in: visibleFrame)
        updatePanelProgrammatically {
            panel.setFrameOrigin(clampedOrigin(origin, size: panel.frame.size, in: visibleFrame))
        }
    }

    private func savedPanelOrigin() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.savedPanelOriginXKey) != nil,
              defaults.object(forKey: Self.savedPanelOriginYKey) != nil else {
            return nil
        }
        return NSPoint(
            x: defaults.double(forKey: Self.savedPanelOriginXKey),
            y: defaults.double(forKey: Self.savedPanelOriginYKey)
        )
    }

    private func savePanelPosition(_ origin: NSPoint) {
        let defaults = UserDefaults.standard
        defaults.set(origin.x, forKey: Self.savedPanelOriginXKey)
        defaults.set(origin.y, forKey: Self.savedPanelOriginYKey)
    }

    private func updatePanelProgrammatically(_ updates: () -> Void) {
        isPositioningProgrammatically = true
        updates()
        isPositioningProgrammatically = false
    }

    private func centeredOrigin(size: NSSize, in visibleFrame: NSRect) -> NSPoint {
        NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2
        )
    }

    private func clampedOrigin(_ origin: NSPoint, size: NSSize, in visibleFrame: NSRect) -> NSPoint {
        let margin: CGFloat = 24
        let minX = visibleFrame.minX + margin
        let maxX = visibleFrame.maxX - size.width - margin
        let minY = visibleFrame.minY + margin
        let maxY = visibleFrame.maxY - size.height - margin
        return NSPoint(
            x: min(max(origin.x, minX), max(minX, maxX)),
            y: min(max(origin.y, minY), max(minY, maxY))
        )
    }

    private func placementVisibleFrame(for point: NSPoint) -> NSRect {
        NSScreen.screens.first { screen in
            screen.frame.contains(point) || screen.visibleFrame.contains(point)
        }?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel, panel === self.panel else {
            return
        }
        guard !isPositioningProgrammatically else {
            return
        }
        savePanelPosition(panel.frame.origin)
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

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

private final class LingobarPanel: NSPanel {
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

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
