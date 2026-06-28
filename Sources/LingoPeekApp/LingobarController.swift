import AppKit
import Carbon.HIToolbox
import LingobarCore
import SwiftUI

@MainActor
final class LingobarController: NSObject, NSWindowDelegate {
    private static let setupPanelSize = NSSize(width: 720, height: 360)
    private static let selectionPanelSize = NSSize(width: 720, height: 532)
    private static let grammarPanelSize = NSSize(width: 720, height: 812)
    private static let selectionLoadingPanelSize = NSSize(width: 720, height: 441)
    private static let inputEmptyPanelSize = NSSize(width: 720, height: 72)
    private static let inputLoadingPanelSize = NSSize(width: 720, height: 287)
    private static let inputResultPanelSize = NSSize(width: 720, height: 377)
    private static let savedPanelOriginXKey = "Lingobar.savedPanelOriginX"
    private static let savedPanelOriginYKey = "Lingobar.savedPanelOriginY"

    private let viewModel: LingobarViewModel
    private let selectionReader = SelectionReader()
    private lazy var hubWindowController = LingobarHubWindowController { [weak self] item in
        self?.presentFromHub(item)
    }
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var hotKeyObserver: NSObjectProtocol?
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

    func start(openSettingsOnLaunch: Bool = false, openHubOnLaunch: LingobarHubSection? = nil) {
        updateStatusItemVisibility()
        hotKeyManager = HotKeyManager { [weak self] in
            Task { @MainActor in
                self?.presentFromHotKey()
            }
        }
        registerConfiguredHotKey()
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: AppSettings.hotKeyDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.registerConfiguredHotKey()
            }
        }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: AppSettings.settingsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.viewModel.actions = AppSettings.actionOrder
                self.viewModel.setupGateStatus = AppSettings.setupGateStatus
                self.updateStatusItemVisibility()
            }
        }
        if let openHubOnLaunch = openHubOnLaunch ?? (openSettingsOnLaunch ? .settings : nil) {
            DispatchQueue.main.async { [weak self] in
                self?.hubWindowController.show(section: openHubOnLaunch)
            }
        } else {
            present(captureSelectionByCopying: false)
        }
    }

    func stop() {
        hotKeyManager?.unregister()
        registeredHotKey = nil
        if let hotKeyObserver {
            NotificationCenter.default.removeObserver(hotKeyObserver)
            self.hotKeyObserver = nil
        }
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
            self.settingsObserver = nil
        }
        removeStatusItem()
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
        if AppSettings.usesGrammarFixture {
            viewModel.presentGrammarFixture()
            let panel = ensurePanel()
            panel.setContentSize(contentSize)
            position(panel)
            show(panel)
            return
        }

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
        guard statusItem == nil else {
            return
        }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "L"
        item.button?.toolTip = "Lingobar"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Lingobar", action: #selector(showFromMenu), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Hide", action: #selector(hideFromMenu), keyEquivalent: "w"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Open Lingobar Hub", action: #selector(showHubFromMenu), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LingoPeek", action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func removeStatusItem() {
        guard let statusItem else {
            return
        }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func updateStatusItemVisibility() {
        if AppSettings.showMenuBarIcon {
            installStatusItem()
        } else {
            removeStatusItem()
        }
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
        panel.onLanguageAction = { [weak self] action in
            self?.viewModel.perform(action)
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
                    self?.hubWindowController.show(section: .settings)
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
            if viewModel.isLoading {
                Self.selectionLoadingPanelSize
            } else if viewModel.action == .grammar, viewModel.grammarResult != nil {
                Self.grammarPanelSize
            } else {
                Self.selectionPanelSize
            }
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
        hubWindowController.show(section: .settings)
    }

    @objc private func showHubFromMenu() {
        hubWindowController.show(section: .collection)
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func presentFromHub(_ item: LingobarHubLibraryItem) {
        let selectedText = [
            item.sourceText,
            item.copyText,
            item.visibleText,
            item.title
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        guard !selectedText.isEmpty else {
            return
        }
        hide()
        viewModel.reopenInlineSelection(selectedText)
        let panel = ensurePanel()
        panel.setContentSize(contentSize)
        position(panel)
        show(panel)
    }
}

private final class LingobarPanel: NSPanel {
    var onCancel: (() -> Void)?
    var onLanguageAction: ((LanguageAction) -> Void)?

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
        if event.type == .keyDown, handleLingobarShortcut(event) {
            return
        }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        handleLingobarShortcut(event) || super.performKeyEquivalent(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    private func handleLingobarShortcut(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              let keyEquivalent = event.charactersIgnoringModifiers,
              let action = LanguageAction.matchingKeyboardShortcut(
                keyEquivalent: keyEquivalent,
                command: event.modifierFlags.contains(.command),
                option: event.modifierFlags.contains(.option),
                control: event.modifierFlags.contains(.control),
                shift: event.modifierFlags.contains(.shift),
                actionOrder: AppSettings.actionOrder
              ),
              action != .copy else {
            return false
        }

        onLanguageAction?(action)
        return true
    }
}
