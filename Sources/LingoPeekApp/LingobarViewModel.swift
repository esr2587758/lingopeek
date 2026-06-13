import AppKit
import Foundation
import LingobarCore

@MainActor
final class LingobarViewModel: ObservableObject {
    @Published var mode: LingobarMode = .selection
    @Published var action: LanguageAction = .translate
    @Published var selectedText = "any sentence can become a small object for translation, parsing, memory, and expression."
    @Published var inputText = "帮我把这个产品描述成自然英文"
    @Published var result: LingobarResult
    @Published var savedPhrases: [SavedPhrase]
    @Published var status = "Ready"
    @Published var isLoading = false

    let actions: [LanguageAction] = [.copy, .translate, .parse, .save, .expand, .examples, .pronounce]
    private let engine = LocalLanguageEngine()
    private let store: PhraseStore

    init(store: PhraseStore = .defaultStore()) {
        let initialText = "any sentence can become a small object for translation, parsing, memory, and expression."
        self.store = store
        self.savedPhrases = (try? store.load()) ?? [
            SavedPhrase(title: "selection-first", note: "以选区为入口，而不是先打开 App。")
        ]

        self.result = LocalLanguageEngine().result(for: .translate, text: initialText)
    }

    func present(selection: String?) {
        if let selection, !selection.isEmpty {
            mode = .selection
            selectedText = selection
            action = .translate
            result = engine.result(for: action, text: activeText)
            runAIIfAvailable(for: action, text: activeText)
        } else {
            mode = .input
            action = .ask
            result = engine.result(for: action, text: activeText)
            status = AppSettings.makeDeepSeekClient() == nil ? "Local mode" : "AI ready"
        }
    }

    func perform(_ newAction: LanguageAction) {
        action = newAction

        switch newAction {
        case .copy:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(activeText, forType: .string)
            result = engine.result(for: newAction, text: activeText)
            status = "Copied"
        case .save:
            saveCurrentPhrase()
            result = engine.result(for: newAction, text: activeText)
            status = "Saved"
        case .translate, .expand, .ask:
            result = engine.result(for: newAction, text: activeText)
            runAIIfAvailable(for: newAction, text: activeText)
        case .parse, .examples, .pronounce:
            result = engine.result(for: newAction, text: activeText)
            status = "Ready"
        }
    }

    func submitInput() {
        mode = .input
        perform(.ask)
    }

    func saveCurrentPhrase() {
        let phrase = SavedPhrase(title: phraseTitle(from: activeText), note: result.summary)
        savedPhrases.insert(phrase, at: 0)
        try? store.save(savedPhrases)
    }

    func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.summary, forType: .string)
        status = "Copied"
    }

    func insertResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.summary, forType: .string)
        status = "Ready to paste"
    }

    private var activeText: String {
        mode == .selection ? selectedText : inputText
    }

    private func runAIIfAvailable(for action: LanguageAction, text: String) {
        guard let aiClient = AppSettings.makeDeepSeekClient() else {
            status = "Local fallback"
            return
        }

        isLoading = true
        status = "Asking DeepSeek"
        Task {
            do {
                let completion = try await aiClient.complete(
                    system: systemPrompt(for: action),
                    user: text
                )
                self.result = LingobarResult(
                    title: result.title,
                    shortcut: result.shortcut,
                    summary: completion,
                    rows: [
                        LingobarRow("来源", "DeepSeek"),
                        LingobarRow("动作", action.title),
                        LingobarRow("原文", text)
                    ],
                    sideTitle: "后续动作",
                    chips: ["复制", "保存", "继续展开"]
                )
                self.status = "AI complete"
            } catch {
                self.status = "AI unavailable"
            }
            self.isLoading = false
        }
    }

    private func systemPrompt(for action: LanguageAction) -> String {
        switch action {
        case .translate:
            "You are Lingobar, a concise English learning assistant. Translate naturally into Chinese and briefly explain one useful expression."
        case .expand:
            "You are Lingobar. Rewrite the user's text into three natural English alternatives: casual, product-like, and formal."
        case .ask:
            "You are Lingobar. Convert the user's idea into natural English and include one concise explanation in Chinese."
        default:
            "You are Lingobar, a concise bilingual English learning assistant."
        }
    }

    private func phraseTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Untitled phrase"
        }
        return String(trimmed.prefix(42))
    }
}
