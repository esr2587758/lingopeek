import AppKit
import Foundation
import LingobarCore

@MainActor
final class LingobarViewModel: ObservableObject {
    @Published var mode: LingobarMode = .selection
    @Published var action: LanguageAction = .translate
    @Published var selectedText = "any sentence can become a small object for translation, parsing, memory, and expression."
    @Published var inputText = ""
    @Published var result: LingobarResult
    @Published var savedPhrases: [SavedPhrase]
    @Published var status = "Ready"
    @Published var isLoading = false
    @Published var showsResult = true
    @Published var isPinned = false
    @Published var selectionSource = "当前 App"
    @Published var setupGateStatus = AppSettings.setupGateStatus
    var onLayoutChanged: (() -> Void)?

    let actions: [LanguageAction] = LanguageAction.selectionActions
    private let store: PhraseStore

    init(store: PhraseStore = .defaultStore()) {
        self.store = store
        self.savedPhrases = (try? store.load()) ?? [
            SavedPhrase(title: "selection-first", note: "以选区为入口，而不是先打开 App。")
        ]

        self.result = LingobarViewModel.pendingResult(for: .translate)
    }

    func present(selection: String?, sourceAppName: String = "当前 App") {
        if let selection, !selection.isEmpty {
            mode = .selection
            selectionSource = sourceAppName
            selectedText = selection
            action = LanguageAction.defaultSelectionAction(for: selection)
            result = Self.pendingResult(for: action)
            showsResult = true
            onLayoutChanged?()
            runAIIfAvailable(for: action, text: activeText)
        } else {
            mode = .input
            action = .rewrite
            result = Self.pendingResult(for: action)
            showsResult = false
            status = "AI 就绪"
            onLayoutChanged?()
        }
    }

    func presentSetupGate(_ setupGateStatus: SetupGateStatus) {
        mode = .setup
        self.setupGateStatus = setupGateStatus
        showsResult = false
        isLoading = false
        status = "需要完成设置"
        onLayoutChanged?()
    }

    func perform(_ newAction: LanguageAction) {
        guard newAction.isAvailable(for: activeText) else {
            status = "\(newAction.title)仅支持英文内容"
            return
        }

        if newAction == .collect {
            saveCurrentPhrase()
            status = "已收藏"
            return
        }

        action = newAction

        switch newAction {
        case .copy:
            copyResult()
        case .translate, .grammar, .rewrite, .examples, .pronounce:
            result = Self.pendingResult(for: newAction)
            showsResult = true
            onLayoutChanged?()
            runAIIfAvailable(for: newAction, text: activeText)
        case .collect:
            break
        }
    }

    func submitInput() {
        mode = .input
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "请输入内容"
            return
        }
        perform(.rewrite)
    }

    func isAvailable(_ languageAction: LanguageAction) -> Bool {
        languageAction.isAvailable(for: activeText)
    }

    func togglePinned() {
        isPinned.toggle()
        status = isPinned ? "已固定" : "已取消固定"
    }

    func saveCurrentPhrase() {
        let collectionTitle = result.defaultCollectionItem?.title ?? (result.defaultCollectionTitle.isEmpty ? activeText : result.defaultCollectionTitle)
        let note = result.defaultCollectionItem?.note ?? result.summary
        let phrase = SavedPhrase(title: phraseTitle(from: collectionTitle), note: note)
        savedPhrases.insert(phrase, at: 0)
        try? store.save(savedPhrases)
    }

    func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.summary, forType: .string)
        status = "已复制"
    }

    func copyInlineSelection(_ text: String) {
        let selectedText = normalizedInlineSelection(text)
        guard !selectedText.isEmpty else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
        status = "已复制选中文本"
    }

    func reopenInlineSelection(_ text: String) {
        let selectedText = normalizedInlineSelection(text)
        guard !selectedText.isEmpty else {
            return
        }
        inputText = ""
        present(selection: selectedText, sourceAppName: "Lingobar")
    }

    func collectInlineSelection(_ text: String) {
        let selectedText = normalizedInlineSelection(text)
        guard !selectedText.isEmpty else {
            return
        }
        let phrase = SavedPhrase(
            title: phraseTitle(from: selectedText),
            note: "来自 \(result.title) 内容区选中文本"
        )
        savedPhrases.insert(phrase, at: 0)
        try? store.save(savedPhrases)
        status = "已收藏选中文本"
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
        guard let aiClient = AppSettings.makeAIClient() else {
            status = "需要 AI 设置"
            result = errorResult(message: "请先完成 AI 设置。")
            return
        }

        isLoading = true
        status = "AI 生成中"
        onLayoutChanged?()
        Task {
            do {
                let completion = try await aiClient.complete(
                    system: systemPrompt(for: action),
                    user: text
                )
                guard let data = completion.data(using: .utf8) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response is not UTF-8"))
                }
                let structured = try JSONDecoder().decode(StructuredLingobarResult.self, from: data)
                self.result = structured.lingobarResult(shortcut: action.shortcut)
                self.status = "AI 完成"
            } catch is DecodingError {
                self.result = self.errorResult(message: "AI 返回格式不正确，请重试。")
                self.status = "格式错误"
            } catch {
                self.result = self.errorResult(message: "AI 请求失败，请重试或检查 AI 设置。")
                self.status = "AI 不可用"
            }
            self.isLoading = false
            self.onLayoutChanged?()
        }
    }

    private func systemPrompt(for action: LanguageAction) -> String {
        let schema = """
        Return ONLY JSON with this schema:
        {"title":"\(action.title)","summary":"...","rows":[{"label":"...","value":"..."}],"chips":["..."],"moreActionTitle":"\(action.moreActionTitle)","defaultCollectionItem":{"title":"...","note":"...","type":"短语|英文|例句|句型|文本"}}
        """
        return switch action {
        case .translate:
            """
            You are Lingobar, a concise English learning assistant. Translate the user's text into Chinese.
            For rows, return these labels exactly and in order:
            1. 通用: natural everyday translation.
            2. 书面: polished written translation.
            3. 意译: freer translation that preserves meaning and tone.
            Optionally add one short 语感 row only if a wording nuance matters.
            Do not invent fixed phrase explanations when the source text does not contain that phrase.
            \(schema)
            """
        case .rewrite:
            "You are Lingobar. Rewrite the user's text into one primary natural English version and a few variants: casual, formal, concise, and idiomatic. \(schema)"
        case .grammar:
            "You are Lingobar. Explain English grammar with structure blocks: main clause, modifiers, logic, and one reusable sentence pattern. \(schema)"
        case .examples:
            "You are Lingobar. Produce 3 to 5 reusable English examples and avoid long explanations. \(schema)"
        case .pronounce:
            "You are Lingobar. Provide pronunciation guidance: stress, linking, and common mistakes. \(schema)"
        default:
            "You are Lingobar, a concise bilingual English learning assistant. \(schema)"
        }
    }

    private func errorResult(message: String) -> LingobarResult {
        LingobarResult(
            title: "出错",
            shortcut: action.shortcut,
            summary: message,
            rows: [
                LingobarRow("重试", "再次触发当前动作"),
                LingobarRow("设置", "打开 AI 设置检查 token、base URL 和 model")
            ],
            sideTitle: "恢复",
            chips: ["重试", "打开 AI 设置"],
            moreActionTitle: "重试",
            defaultCollectionTitle: ""
        )
    }

    private static func pendingResult(for action: LanguageAction) -> LingobarResult {
        LingobarResult(
            title: action.title,
            shortcut: action.shortcut,
            summary: "正在请求 AI…",
            rows: [],
            sideTitle: "后续动作",
            chips: [],
            moreActionTitle: action.moreActionTitle,
            defaultCollectionTitle: ""
        )
    }

    private func phraseTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Untitled phrase"
        }
        return String(trimmed.prefix(42))
    }

    private func normalizedInlineSelection(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
