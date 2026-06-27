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
    @Published var grammarResult: GrammarResult?
    @Published var savedPhrases: [SavedPhrase]
    @Published var status = "Ready"
    @Published var isLoading = false
    @Published var showsResult = true
    @Published var isPinned = false
    @Published var selectionSource = "当前 App"
    @Published var setupGateStatus = AppSettings.setupGateStatus
    @Published var loadingStartedAt: Date?
    var onLayoutChanged: (() -> Void)?

    @Published var actions: [LanguageAction] = AppSettings.actionOrder
    private let store: PhraseStore
    private let historyStore: LingobarHistoryStore
    private var activeAIRequestID = UUID()

    init(store: PhraseStore = .defaultStore(), historyStore: LingobarHistoryStore = .defaultStore()) {
        self.store = store
        self.historyStore = historyStore
        self.savedPhrases = (try? store.load()) ?? [
            SavedPhrase(title: "selection-first", note: "以选区为入口，而不是先打开 App。")
        ]

        self.result = LingobarViewModel.pendingResult(for: .translate)
    }

    func present(selection: String?, sourceAppName: String = "当前 App") {
        actions = AppSettings.actionOrder

        if let selection, !selection.isEmpty {
            mode = .selection
            selectionSource = sourceAppName
            selectedText = selection
            action = configuredDefaultSelectionAction(for: selection)
            result = Self.pendingResult(for: action)
            grammarResult = nil
            showsResult = true
            loadingStartedAt = nil
            onLayoutChanged?()
            runAIIfAvailable(for: action, text: activeText)
        } else {
            mode = .input
            action = .rewrite
            inputText = AppSettings.autoReadClipboard ? clipboardText() : ""
            result = Self.pendingResult(for: action)
            grammarResult = nil
            showsResult = false
            status = "AI 就绪"
            loadingStartedAt = nil
            onLayoutChanged?()
        }
    }

    func presentGrammarFixture(sourceAppName: String = "Lingobar") {
        actions = AppSettings.actionOrder
        let grammar = GrammarResult.fixture(id: AppSettings.grammarFixtureID) ?? .mockupFixture
        mode = .selection
        selectionSource = sourceAppName
        selectedText = grammar.sourceSentence
        action = .grammar
        grammarResult = grammar
        result = grammar.lingobarResult(shortcut: LanguageAction.grammar.shortcut)
        showsResult = true
        isLoading = false
        loadingStartedAt = nil
        status = "语法 fixture"
        onLayoutChanged?()
    }

    func presentSetupGate(_ setupGateStatus: SetupGateStatus) {
        actions = AppSettings.actionOrder
        mode = .setup
        self.setupGateStatus = setupGateStatus
        showsResult = false
        isLoading = false
        loadingStartedAt = nil
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
        grammarResult = nil

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
        let collectionTitle: String
        let note: String
        if AppSettings.collectionTarget == .originalSelection {
            collectionTitle = activeText
            note = "来自原文"
        } else {
            collectionTitle = result.defaultCollectionItem?.title ?? (result.defaultCollectionTitle.isEmpty ? activeText : result.defaultCollectionTitle)
            note = result.defaultCollectionItem?.note ?? result.summary
        }
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

    private func configuredDefaultSelectionAction(for selection: String) -> LanguageAction {
        let configured = LanguageAction.defaultSelectionAction(for: selection) == .rewrite
            ? AppSettings.defaultChineseMixedAction
            : AppSettings.defaultEnglishAction
        return configured.isAvailable(for: selection)
            ? configured
            : LanguageAction.defaultSelectionAction(for: selection)
    }

    private func clipboardText() -> String {
        NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
            grammarResult = nil
            loadingStartedAt = nil
            result = errorResult(message: "请先完成 AI 设置。")
            return
        }

        let historySourceText = text
        let historySourceAppName = mode == .input ? "输入模式" : selectionSource
        let requestID = UUID()
        activeAIRequestID = requestID
        isLoading = true
        loadingStartedAt = Date()
        status = "AI 生成中"
        onLayoutChanged?()
        Task {
            do {
                let completion = try await aiClient.complete(
                    system: systemPrompt(for: action),
                    user: text
                )
                let json = try StructuredJSONExtractor.extractObject(from: completion)
                guard let data = json.data(using: .utf8) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response is not UTF-8"))
                }
                guard self.activeAIRequestID == requestID else {
                    return
                }
                if action == .grammar {
                    let grammar = try JSONDecoder().decode(GrammarResult.self, from: data)
                    self.grammarResult = grammar
                    self.result = grammar.lingobarResult(shortcut: action.shortcut)
                } else {
                    let structured = try JSONDecoder().decode(StructuredLingobarResult.self, from: data)
                    self.grammarResult = nil
                    self.result = structured.lingobarResult(shortcut: action.shortcut)
                }
                self.recordCompletedHistory(
                    action: action,
                    sourceText: historySourceText,
                    sourceAppName: historySourceAppName
                )
                self.status = "AI 完成"
            } catch is DecodingError {
                guard self.activeAIRequestID == requestID else {
                    return
                }
                self.grammarResult = nil
                self.result = self.errorResult(message: "AI 返回结构不符合语法面板，请重试。")
                self.status = "格式错误"
            } catch {
                guard self.activeAIRequestID == requestID else {
                    return
                }
                self.grammarResult = nil
                self.result = self.errorResult(message: self.userFacingAIErrorMessage(error))
                self.status = "AI 不可用"
            }
            guard self.activeAIRequestID == requestID else {
                return
            }
            self.isLoading = false
            self.loadingStartedAt = nil
            self.onLayoutChanged?()
        }
    }

    private func recordCompletedHistory(
        action: LanguageAction,
        sourceText: String,
        sourceAppName: String
    ) {
        guard let record = LingobarHistoryRecord.make(
            action: action,
            sourceText: sourceText,
            sourceAppName: sourceAppName,
            result: result
        ) else {
            return
        }
        _ = try? historyStore.append(record)
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
            grammarSystemPrompt()
        case .examples:
            "You are Lingobar. Produce 3 to 5 reusable English examples and avoid long explanations. \(schema)"
        case .pronounce:
            "You are Lingobar. Provide pronunciation guidance: stress, linking, and common mistakes. \(schema)"
        default:
            "You are Lingobar, a concise bilingual English learning assistant. \(schema)"
        }
    }

    private func grammarSystemPrompt() -> String {
        """
        You are Lingobar, a precise bilingual English grammar visualization engine.

        Analyze the user's English text for a native macOS grammar panel. The user interface is Chinese, so all explanations, labels, notes, meanings, and grammar terminology must be in Simplified Chinese. Keep English examples and sentence fragments in English.

        Return ONLY valid JSON. Do not return Markdown, comments, or extra prose.

        Scope rules:
        - If the input contains multiple English sentences, analyze the first complete/main sentence and set analysisScopeNote.
        - If the input is very long, choose the sentence with the clearest grammar value.
        - Do not analyze Chinese or mixed-language text.
        - Use phrase-level chunks, not every word as a top-level chunk.
        - Each chunk may include word-level tokens for drilldown.

        Use only these role values:
        subject = 主语
        predicate = 谓语
        object = 宾语
        attr = 定语
        adv = 状语
        appos = 同位语
        conj = 连接词

        Return JSON with this exact shape:
        {
          "title": "语法解析",
          "sourceSentence": "original English sentence being analyzed",
          "chineseMeaning": "自然中文释义",
          "analysisScopeNote": "分析范围说明，可为空字符串",
          "chunks": [
            {
              "id": "short stable id, e.g. s, v, o, d1",
              "role": "subject|predicate|object|attr|adv|appos|conj",
              "text": "English phrase chunk",
              "label": "中文成分名",
              "note": "一句中文解释这个成分的作用",
              "tokens": [
                { "w": "word or short phrase", "pos": "中文词性/形式", "infl": "中文形态说明" }
              ]
            }
          ],
          "dependencies": [
            { "from": "chunk id", "to": "chunk id", "label": "主谓|动宾|修饰|同位|连接|其他简短中文关系" }
          ],
          "tree": {
            "label": "中文层级标签",
            "role": "predicate",
            "text": "English phrase",
            "children": []
          },
          "trunk": {
            "core": [
              { "w": "English core phrase", "role": "subject|predicate|object|attr|adv|appos|conj" }
            ],
            "dropped": ["被剥离的修饰成分，中文说明"],
            "coreZh": "主干中文意思"
          },
          "tenseVoice": [
            {
              "scope": "主句/从句名称",
              "verb": "English verb phrase",
              "tense": "一般现在时/一般过去时/现在完成时等",
              "aspect": "一般体/进行体/完成体等",
              "voice": "主动|被动",
              "mood": "陈述|疑问|祈使|虚拟",
              "why": "为什么这里用这个时态/语态/语气",
              "svo": { "agent": "施动者", "action": "动作", "receiver": "承受者，可为 null" }
            }
          ],
          "wordOrder": {
            "en": [
              { "id": 1, "text": "English segment", "role": "subject|predicate|object|attr|adv|appos|conj", "zhPos": 1, "moved": false }
            ],
            "zhOrder": [1, 2, 3],
            "zhText": ["中文重排片段"],
            "note": "一句话说明中英语序差异"
          },
          "pattern": { "en": "reusable English sentence pattern", "zh": "中文句型解释" },
          "collocations": [
            { "phrase": "English collocation", "pos": "v. phr. / n. phr. etc.", "zh": "中文意思", "note": "使用说明", "example": "Short English example" }
          ],
          "phrases": [
            { "en": "short useful phrase", "zh": "中文意思" }
          ],
          "grammarPoints": [
            { "tag": "从句|语态|修饰|非谓语|时态|搭配", "title": "中文标题", "body": "中文解释" }
          ],
          "defaultCollectionItem": {
            "title": "same as pattern.en",
            "note": "same as pattern.zh",
            "type": "句型"
          }
        }

        Quality rules:
        - Prefer 4 to 7 chunks.
        - Prefer 2 to 5 dependency relations.
        - Prefer 2 to 4 tenseVoice items.
        - Prefer 2 to 4 collocations.
        - Prefer 3 to 6 phrases.
        - Prefer 3 to 5 grammarPoints.
        - Keep every Chinese explanation concise.
        - Do not invent advanced grammar points that are not actually present in the sentence.
        - The reusable pattern must be genuinely reusable, not just the original sentence with words removed.
        """
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

    private func userFacingAIErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorTimedOut {
            return "AI 请求超时，请重试；语法解析可能需要更长生成时间。"
        }
        if let providerError = error as? OpenAICompatibleError {
            switch providerError {
            case .server(let statusCode, _):
                return "AI 请求失败（HTTP \(statusCode)），请检查 token、base URL 和 model。"
            case .unusableConfiguration:
                return "AI 设置不完整，请检查 token、base URL 和 model。"
            case .invalidResponse:
                return "AI 服务返回了无效响应，请重试。"
            case .emptyCompletion:
                return "AI 返回了空结果，请重试。"
            }
        }
        return "AI 请求失败，请重试或检查 AI 设置。"
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
