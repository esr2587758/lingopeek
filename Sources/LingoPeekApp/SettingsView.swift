import AppKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.apiKeyKey) private var apiKey = ""
    @AppStorage(AppSettings.modelKey) private var model = AppSettings.defaultModel
    @AppStorage(AppSettings.baseURLKey) private var baseURL = AppSettings.defaultBaseURL

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            aiSection
            interactionSection
            storageSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 520, height: 520, alignment: .topLeading)
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
        SettingsSection(title: "DeepSeek") {
            LabeledContent("Base URL") {
                TextField("https://api.deepseek.com", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            LabeledContent("Model") {
                TextField("deepseek-v4-flash", text: $model)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            LabeledContent("API Key") {
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            Text("Environment variables still take priority: DEEPSEEK_API_KEY, DEEPSEEK_MODEL, DEEPSEEK_BASE_URL.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var interactionSection: some View {
        SettingsSection(title: "Interaction") {
            LabeledContent("Toggle shortcut") {
                Text("Option-Command-L")
                    .foregroundStyle(.secondary)
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
