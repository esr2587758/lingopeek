import AppKit
import Carbon.HIToolbox
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.modelKey) private var model = AppSettings.defaultModel
    @AppStorage(AppSettings.baseURLKey) private var baseURL = AppSettings.defaultBaseURL
    @AppStorage(AppSettings.hotKeyCodeKey) private var hotKeyCode = Int(LingobarHotKey.default.keyCode)
    @AppStorage(AppSettings.hotKeyModifiersKey) private var hotKeyModifiers = Int(LingobarHotKey.default.carbonModifiers)
    @State private var tokenInput = ""
    @State private var tokenConfigured = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            aiSection
            interactionSection
            storageSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 540, height: 560, alignment: .topLeading)
        .onAppear(perform: refreshTokenStatus)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Lingobar Settings")
                .font(.title2.bold())
            Text("Configure AI, permissions, and local learning data.")
                .foregroundStyle(.secondary)
        }
    }

    private var aiSection: some View {
        SettingsSection(title: "AI 设置") {
            LabeledContent("Base URL") {
                TextField("https://api.deepseek.com", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            LabeledContent("Model") {
                TextField("deepseek-chat", text: $model)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            LabeledContent("API Token") {
                HStack(spacing: 8) {
                    SecureField(tokenConfigured ? "已配置，输入新 token 可替换" : "粘贴 API token", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                    Button("保存") {
                        LocalTokenStore.saveToken(tokenInput)
                        tokenInput = ""
                        refreshTokenStatus()
                    }
                    .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            LabeledContent("Token Status") {
                HStack(spacing: 8) {
                    Text(tokenConfigured ? "已配置" : "未配置")
                        .foregroundStyle(tokenConfigured ? .green : .secondary)
                    Button("清除") {
                        LocalTokenStore.deleteToken()
                        tokenInput = ""
                        refreshTokenStatus()
                    }
                    .disabled(!tokenConfigured)
                }
            }
            Text("Environment variables take priority: AI_API_TOKEN, AI_MODEL, AI_BASE_URL. DeepSeek-compatible legacy names are still accepted.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var interactionSection: some View {
        SettingsSection(title: "Interaction") {
            LabeledContent("Toggle shortcut") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        HotKeyRecorder(hotKey: hotKeyBinding)
                            .frame(width: 160, height: 28)
                        Button("恢复默认") {
                            AppSettings.resetHotKey()
                            hotKeyCode = Int(LingobarHotKey.default.keyCode)
                            hotKeyModifiers = Int(LingobarHotKey.default.carbonModifiers)
                        }
                    }
                    Text(hotKeyBinding.wrappedValue.usesSingleKey ? "单键会全局占用这个按键；建议优先使用 F 键或组合键。" : "点击后按一个按键或组合键，Esc 取消。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent("Move panel") {
                Text("Drag the small header strip at the top of Lingobar.")
                    .foregroundStyle(.secondary)
            }
            Button("Open Accessibility Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private var storageSection: some View {
        SettingsSection(title: "Local Data") {
            LabeledContent("Phrase library") {
                Text("~/Library/Application Support/LingoPeek/phrases.json")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Button("Open Application Support Folder") {
                let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                NSWorkspace.shared.open(base.appending(path: "LingoPeek", directoryHint: .isDirectory))
            }
        }
    }
}

private extension SettingsView {
    var hotKeyBinding: Binding<LingobarHotKey> {
        Binding {
            LingobarHotKey(
                keyCode: UInt32(hotKeyCode),
                carbonModifiers: UInt32(hotKeyModifiers)
            )
        } set: { hotKey in
            hotKeyCode = Int(hotKey.keyCode)
            hotKeyModifiers = Int(hotKey.carbonModifiers)
            AppSettings.saveHotKey(hotKey)
        }
    }

    func refreshTokenStatus() {
        tokenConfigured = !LocalTokenStore.readToken()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
            || !(ProcessInfo.processInfo.environment["AI_API_TOKEN"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
            || !(ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
}

private struct HotKeyRecorder: NSViewRepresentable {
    @Binding var hotKey: LingobarHotKey

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> HotKeyRecorderButton {
        let button = HotKeyRecorderButton()
        button.bezelStyle = .rounded
        button.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        button.target = context.coordinator
        button.action = #selector(Coordinator.startRecording(_:))
        button.onKeyDown = { [weak coordinator = context.coordinator] event in
            coordinator?.handleKeyDown(event) ?? false
        }
        return button
    }

    func updateNSView(_ button: HotKeyRecorderButton, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateTitle(button)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: HotKeyRecorder
        private var isRecording = false
        private weak var activeButton: HotKeyRecorderButton?
        private var keyMonitor: Any?

        init(_ parent: HotKeyRecorder) {
            self.parent = parent
        }

        @objc func startRecording(_ sender: HotKeyRecorderButton) {
            isRecording = true
            activeButton = sender
            installKeyMonitor()
            updateTitle(sender)
            sender.window?.makeFirstResponder(sender)
        }

        func handleKeyDown(_ event: NSEvent) -> Bool {
            guard isRecording else {
                return false
            }

            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return true
            }

            guard let nextHotKey = LingobarHotKey(event: event) else {
                return true
            }

            parent.hotKey = nextHotKey
            stopRecording()
            return true
        }

        func updateTitle(_ button: HotKeyRecorderButton) {
            button.title = isRecording ? "按下快捷键…" : parent.hotKey.displayString
        }

        private func installKeyMonitor() {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                let handled: Bool = MainActor.assumeIsolated {
                    guard let self else {
                        return false
                    }
                    return self.handleKeyDown(event)
                }
                return handled ? nil : event
            }
        }

        private func stopRecording() {
            isRecording = false
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            activeButton.map(updateTitle)
        }
    }
}

@MainActor
private final class HotKeyRecorderButton: NSButton {
    var onKeyDown: (@MainActor (NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if onKeyDown?(event) == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

private struct SettingsSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
