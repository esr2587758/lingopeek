import AppKit
import Foundation
import LingobarCore

private enum LingobarAICompletionResult: Sendable {
    case grammar(GrammarResult)
    case structured(StructuredLingobarResult)
}

struct LingobarFollowUpKey: Decodable, Equatable, Sendable {
    var term: String
    var zh: String
}

private struct LingobarFollowUpCompletion: Decodable, Sendable {
    var answer: String
    var key: LingobarFollowUpKey?

    enum CodingKeys: String, CodingKey {
        case answer
        case key
        case keyTerm
        case keyMeaning
    }

    init(answer: String, key: LingobarFollowUpKey?) {
        self.answer = answer
        self.key = key
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? ""
        if let key = try container.decodeIfPresent(LingobarFollowUpKey.self, forKey: .key),
           !key.term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.key = key
        } else if let term = try container.decodeIfPresent(String.self, forKey: .keyTerm),
                  let meaning = try container.decodeIfPresent(String.self, forKey: .keyMeaning),
                  !term.isEmpty {
            self.key = LingobarFollowUpKey(term: term, zh: meaning)
        } else {
            self.key = nil
        }
    }
}

private struct LingobarFollowUpContextSnapshot: Sendable {
    var isAnchored: Bool
    var mode: LingobarMode
    var actionTitle: String
    var sourceText: String
    var resultTitle: String
    var resultSummary: String
    var resultRows: [LingobarRow]
    var conversation: [LingobarFollowUpConversationTurn]
}

struct LingobarFollowUpExchange: Identifiable, Equatable, Sendable {
    var id: UUID
    var question: String
    var answer: String
    var key: LingobarFollowUpKey?
    var isLoading: Bool

    init(
        id: UUID = UUID(),
        question: String,
        answer: String = "",
        key: LingobarFollowUpKey? = nil,
        isLoading: Bool = false
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.key = key
        self.isLoading = isLoading
    }
}

private struct LingobarFollowUpConversationTurn: Sendable {
    var question: String
    var answer: String
}

private enum LingobarFollowUpCompletionDecoder {
    static func decode(
        aiClient: OpenAICompatibleClient,
        context: LingobarFollowUpContextSnapshot,
        question: String
    ) async throws -> LingobarFollowUpCompletion {
        let completion = try await aiClient.complete(
            system: systemPrompt(context: context),
            user: userPrompt(context: context, question: question),
            maxTokens: 900
        )
        let json = try StructuredJSONExtractor.extractObject(from: completion)
        let decoded = try JSONDecoder().decode(LingobarFollowUpCompletion.self, from: Data(json.utf8))
        guard !decoded.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAICompatibleError.emptyCompletion
        }
        return decoded
    }

    private static func systemPrompt(context: LingobarFollowUpContextSnapshot) -> String {
        """
        You are Lingobar's follow-up chatbot for quick English-learning questions.
        The UI language is Simplified Chinese. Answer the user's follow-up directly and concisely.
        \(context.isAnchored ? "Use the provided Lingobar context as the main evidence. Do not invent a new source sentence." : "The user has turned off anchoring, so answer as a standalone quick question.")
        Use previous follow-up turns as conversation memory when the latest question refers to prior answers, wording, examples, or explanations.
        Keep the answer practical: 2-5 short paragraphs or bullets, no long essay. Do not use Markdown formatting markers such as ** or backticks.
        Return ONLY JSON with this schema:
        {"answer":"简体中文回答，可少量包含英文术语","key":{"term":"one useful English expression, or empty string","zh":"简短中文释义"}}
        If there is no useful key expression, return "key": null.
        """
    }

    private static func userPrompt(context: LingobarFollowUpContextSnapshot, question: String) -> String {
        let rowText = context.resultRows
            .prefix(6)
            .map { "- \($0.label): \($0.value)" }
            .joined(separator: "\n")
        let conversationText = context.conversation
            .suffix(6)
            .enumerated()
            .map { index, turn in
                """
                Turn \(index + 1)
                User: \(turn.question)
                Lingobar: \(turn.answer)
                """
            }
            .joined(separator: "\n\n")
        return """
        Follow-up question:
        \(question)

        Anchored context: \(context.isAnchored ? "on" : "off")
        Mode: \(context.mode.rawValue)
        Current action: \(context.actionTitle)
        Source text:
        \(context.sourceText)

        Current result title: \(context.resultTitle)
        Current result summary:
        \(context.resultSummary)

        Current result rows:
        \(rowText.isEmpty ? "(none)" : rowText)

        Previous follow-up turns:
        \(conversationText.isEmpty ? "(none)" : conversationText)
        """
    }
}

private struct GrammarRequestKey: Hashable {
    var sourceText: String
    var baseURLString: String
    var model: String
}

private enum LingobarAICompletionDecoder {
    typealias GrammarSpineHandler = @Sendable (GrammarResult) async -> Void

    static func decode(
        action: LanguageAction,
        aiClient: OpenAICompatibleClient,
        system: String,
        user: String
    ) async throws -> LingobarAICompletionResult {
        if action == .grammar {
            let completion = try await aiClient.complete(system: system, user: user)
            let json = try StructuredJSONExtractor.extractObject(from: completion)
            guard let data = json.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response is not UTF-8"))
            }
            return .grammar(try JSONDecoder().decode(GrammarResult.self, from: data))
        }
        return .structured(try await decodeStructured(action: action, aiClient: aiClient, system: system, user: user))
    }

    static func decodeCustom(
        aiClient: OpenAICompatibleClient,
        system: String,
        user: String
    ) async throws -> LingobarAICompletionResult {
        .structured(try await decodeStructured(action: nil, aiClient: aiClient, system: system, user: user))
    }

    static func decodeGrammar(
        aiClient: OpenAICompatibleClient,
        user: String,
        onSpine: GrammarSpineHandler? = nil
    ) async throws -> GrammarResult {
        var spine = try await decodeGrammarSpine(aiClient: aiClient, user: user)
        if spine.sourceSentence.isEmpty {
            spine.sourceSentence = user
        }
        if spine.chineseMeaning.isEmpty {
            spine.chineseMeaning = "中文释义暂缺。"
        }
        spine.chunks = GrammarResult.normalizedChunks(spine.chunks, in: spine.sourceSentence)
        let partial = makePartialGrammar(from: spine)
        if let onSpine {
            await onSpine(partial)
        }

        let canonical = try canonicalParseJSON(from: spine)
        async let tokens = decodeObject(
            GrammarTokensCompletion.self,
            aiClient: aiClient,
            system: grammarTokensPrompt(canonical: canonical),
            user: "Return the requested JSON now.",
            maxTokens: 1000
        )
        async let dependenciesTree = decodeObject(
            GrammarDependenciesTreeCompletion.self,
            aiClient: aiClient,
            system: grammarDependenciesTreePrompt(canonical: canonical),
            user: "Return the requested JSON now.",
            maxTokens: 1000
        )
        async let trunkOrder = decodeObject(
            GrammarTrunkOrderCompletion.self,
            aiClient: aiClient,
            system: grammarTrunkOrderPrompt(canonical: canonical),
            user: "Return the requested JSON now.",
            maxTokens: 1000
        )
        async let tenseVoice = decodeObject(
            GrammarTenseVoiceCompletion.self,
            aiClient: aiClient,
            system: grammarTenseVoicePrompt(canonical: canonical),
            user: "Return the requested JSON now.",
            maxTokens: 900
        )
        async let knowledge = decodeObject(
            GrammarKnowledgeCompletion.self,
            aiClient: aiClient,
            system: grammarKnowledgePrompt(canonical: canonical),
            user: "Return the requested JSON now.",
            maxTokens: 1300
        )

        return try await makeGrammarResult(
            spine: spine,
            tokens: tokens,
            dependenciesTree: dependenciesTree,
            trunkOrder: trunkOrder,
            tenseVoice: tenseVoice,
            knowledge: knowledge
        )
    }

    private static func decodeGrammarSpine(
        aiClient: OpenAICompatibleClient,
        user: String
    ) async throws -> GrammarSpineCompletion {
        do {
            return try await decodeObject(
                GrammarSpineCompletion.self,
                aiClient: aiClient,
                system: grammarSpinePrompt(),
                user: user,
                maxTokens: 1200
            )
        } catch {
            return GrammarSpineCompletion.recovery(sourceText: user)
        }
    }

    private static func decodeObject<T: Decodable>(
        _ type: T.Type,
        aiClient: OpenAICompatibleClient,
        system: String,
        user: String,
        maxTokens: Int
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<2 {
            do {
                let retrySuffix = """

                Previous response was not valid for the requested schema. Return ONLY one valid JSON object now.
                """
                let request = attempt == 0 ? user : user + retrySuffix
                let completion = try await aiClient.complete(system: system, user: request, maxTokens: maxTokens)
                let json = try StructuredJSONExtractor.extractObject(from: completion)
                return try JSONDecoder().decode(type, from: Data(json.utf8))
            } catch {
                lastError = error
                if attempt == 0 {
                    try await Task.sleep(nanoseconds: 200_000_000)
                }
            }
        }
        throw lastError ?? DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response could not be decoded"))
    }

    private static func decodeStructured(
        action: LanguageAction?,
        aiClient: OpenAICompatibleClient,
        system: String,
        user: String
    ) async throws -> StructuredLingobarResult {
        var lastError: Error?
        for attempt in 0..<2 {
            do {
                let retrySuffix = """

                Previous response was not valid for the requested schema. Return ONLY one valid JSON object now.
                """
                let request = attempt == 0 ? user : user + retrySuffix
                let completion = try await aiClient.complete(system: system, user: request)
                let json = try StructuredJSONExtractor.extractObject(from: completion)
                let result = try JSONDecoder().decode(StructuredLingobarResult.self, from: Data(json.utf8))
                try validateStructuredResult(result, action: action)
                return result
            } catch {
                lastError = error
                if attempt == 0 {
                    try await Task.sleep(nanoseconds: 200_000_000)
                }
            }
        }
        throw lastError ?? DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response could not be decoded"))
    }

    private static func validateStructuredResult(_ result: StructuredLingobarResult, action: LanguageAction?) throws {
        guard action == .rewrite else {
            return
        }

        let values = [result.summary, result.defaultCollectionItem.title] + result.rows.map(\.value)
        guard values.contains(where: containsCJKCharacters) else {
            return
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [],
                debugDescription: "Rewrite response values must be English-only."
            )
        )
    }

    private static func containsCJKCharacters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }

    private static func makePartialGrammar(from spine: GrammarSpineCompletion) -> GrammarResult {
        let sourceSentence = spine.sourceSentence.isEmpty ? "" : spine.sourceSentence
        return GrammarResult(
            title: spine.title,
            sourceSentence: sourceSentence,
            chineseMeaning: spine.chineseMeaning,
            analysisScopeNote: spine.analysisScopeNote,
            chunks: spine.chunks,
            dependencies: [],
            tree: GrammarTreeNode(
                label: "主句",
                role: .predicate,
                text: sourceSentence,
                children: spine.chunks.map { GrammarTreeNode(label: $0.label, role: $0.role, text: $0.text) }
            ),
            trunk: GrammarTrunk(
                core: spine.chunks
                    .filter { [.subject, .predicate, .object].contains($0.role) }
                    .map { GrammarTrunkItem(w: $0.text, role: $0.role) },
                dropped: spine.chunks
                    .filter { ![.subject, .predicate, .object].contains($0.role) }
                    .map { "\($0.text)（\($0.label)）" },
                coreZh: spine.chineseMeaning
            ),
            tenseVoice: [],
            wordOrder: GrammarWordOrder(
                en: spine.chunks.enumerated().map { index, chunk in
                    GrammarOrderSegment(id: index + 1, text: chunk.text, role: chunk.role, zhPos: index + 1)
                },
                zhOrder: spine.chunks.indices.map { $0 + 1 },
                zhText: spine.chunks.map(\.label),
                note: "正在补全语序对照。"
            ),
            pattern: spine.pattern,
            collocations: [],
            phrases: [],
            grammarPoints: [],
            defaultCollectionItem: spine.defaultCollectionItem
        )
    }

    private static func makeGrammarResult(
        spine: GrammarSpineCompletion,
        tokens: GrammarTokensCompletion,
        dependenciesTree: GrammarDependenciesTreeCompletion,
        trunkOrder: GrammarTrunkOrderCompletion,
        tenseVoice: GrammarTenseVoiceCompletion,
        knowledge: GrammarKnowledgeCompletion
    ) -> GrammarResult {
        let tokensByID = tokens.chunks.reduce(into: [String: [GrammarToken]]()) { partial, item in
            partial[item.id] = item.tokens
        }
        let chunks = spine.chunks.map { chunk in
            GrammarChunk(
                id: chunk.id,
                role: chunk.role,
                text: chunk.text,
                label: chunk.label,
                note: chunk.note,
                tokens: tokensByID[chunk.id] ?? chunk.tokens
            )
        }

        return GrammarResult(
            title: spine.title,
            sourceSentence: spine.sourceSentence,
            chineseMeaning: spine.chineseMeaning,
            analysisScopeNote: spine.analysisScopeNote,
            chunks: chunks,
            dependencies: dependenciesTree.dependencies,
            tree: dependenciesTree.tree,
            trunk: trunkOrder.trunk,
            tenseVoice: tenseVoice.tenseVoice,
            wordOrder: trunkOrder.wordOrder,
            pattern: spine.pattern,
            collocations: knowledge.collocations,
            phrases: knowledge.phrases,
            grammarPoints: knowledge.grammarPoints,
            defaultCollectionItem: spine.defaultCollectionItem
        )
    }

    private static func canonicalParseJSON(from spine: GrammarSpineCompletion) throws -> String {
        let payload = GrammarCanonicalParse(
            sourceSentence: spine.sourceSentence,
            chunks: spine.chunks.map {
                GrammarCanonicalChunk(id: $0.id, role: $0.role, text: $0.text, label: $0.label, note: $0.note)
            },
            pattern: spine.pattern
        )
        let data = try JSONEncoder().encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    private static func grammarSpinePrompt() -> String {
        """
        You are Lingobar, a concise bilingual English grammar engine.
        The UI language is Simplified Chinese. Return ONLY valid JSON.
        Analyze the user's English sentence. Do not analyze Chinese or mixed-language text.
        Use only role values: subject, predicate, object, attr, adv, appos, conj.
        Return keys: title, sourceSentence, chineseMeaning, analysisScopeNote, chunks, pattern, defaultCollectionItem.
        chunks must be 5-10 flat, non-overlapping phrase-level items with id, role, text, label, note only. Do not include tokens.
        Chunks must follow the source sentence order and must not repeat text.
        Do not include both a parent clause and its child subject/predicate/object chunks in chunks.
        For long adverbial, participial, relative, appositive, or object clauses, prefer smaller internal chunks such as connector, clause subject, clause predicate, clause object/complement, and short modifiers.
        Keep each chunk under 10 English words when possible.
        Keep Chinese explanations short.
        pattern has en and zh. defaultCollectionItem has title, note, type, and type must be 句型.
        """
    }

    private static func grammarTokensPrompt(canonical: String) -> String {
        """
        You are Lingobar. The UI language is Simplified Chinese. Return ONLY valid JSON.
        Use this canonical parse exactly; do not rename chunk ids or change chunk text:
        \(canonical)

        Return key: chunks.
        For each canonical chunk, return { "id": "...", "tokens": [...] }.
        tokens are important words or short phrases with w, pos, infl. Keep token lists concise.
        pos must be readable to Chinese learners; do not return bare abbreviations like adv or prep without a Chinese note.
        """
    }

    private static func grammarDependenciesTreePrompt(canonical: String) -> String {
        """
        You are Lingobar. The UI language is Simplified Chinese. Return ONLY valid JSON.
        Use this canonical parse exactly; do not rename chunk ids or change chunk text:
        \(canonical)

        Return keys: dependencies, tree.
        dependencies must be objects only: { "from": "<chunk id>", "to": "<chunk id>", "label": "主谓" }.
        Do not use tuple arrays for dependencies. Reference canonical chunk ids only and use labels such as 主谓, 动宾, 修饰, 同位, 连接.
        tree is a compact nested clause tree with label, role, text, children.
        tree labels must be readable to Chinese learners. Prefer Chinese labels such as 主句, 状语短语, 连接词; if using abbreviations such as S, NP, VP, AdvP, or ConjP, append Chinese in the same label, for example "AdvP（状语短语）".
        """
    }

    private static func grammarTrunkOrderPrompt(canonical: String) -> String {
        """
        You are Lingobar. The UI language is Simplified Chinese. Return ONLY valid JSON.
        Use this canonical parse exactly; do not rename chunk ids or change chunk text:
        \(canonical)

        Return keys: trunk, wordOrder.
        trunk has core[{w,role}], dropped[string], coreZh. dropped must contain strings only.
        wordOrder has en[{id,text,role,zhPos,moved}], zhOrder, zhText, note. id and zhPos must be JSON integers, not strings.
        zhOrder must be an integer array. zhText must be a string array, not one joined string.
        Keep Chinese explanations short.
        """
    }

    private static func grammarTenseVoicePrompt(canonical: String) -> String {
        """
        You are Lingobar. The UI language is Simplified Chinese. Return ONLY valid JSON.
        Use this canonical parse exactly:
        \(canonical)

        Return key: tenseVoice.
        Include 2-4 items. Each item has scope, verb, tense, aspect, voice, mood, why, svo{agent,action,receiver}.
        tense, aspect, voice, and mood must be readable to Chinese learners. Prefer Chinese; if using English terms such as past, simple, active, indicative, progressive, or non-finite, append Chinese in the same field.
        Keep why short and do not invent tense points absent from the sentence.
        """
    }

    private static func grammarKnowledgePrompt(canonical: String) -> String {
        """
        You are Lingobar. The UI language is Simplified Chinese. Return ONLY valid JSON.
        Use this canonical parse exactly:
        \(canonical)

        Return keys: collocations, phrases, grammarPoints.
        These items are shared below every grammar visualization tab; choose sentence-specific learning points that help in annotated, dependency, tree, trunk, tense, and word-order views.
        collocations: 2-4 items with phrase, pos, zh, note, example.
        collocations.pos must not be a bare abbreviation. Use Chinese or abbreviation plus Chinese, for example "v. phr.（动词短语）", "prep（介词）", or "adv（副词/状语）".
        phrases: 3-6 items with en, zh.
        grammarPoints: 3-5 items with tag, title, body.
        Keep every Chinese explanation concise.
        """
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}

private struct GrammarSpineCompletion: Decodable, Sendable {
    var title: String
    var sourceSentence: String
    var chineseMeaning: String
    var analysisScopeNote: String
    var chunks: [GrammarChunk]
    var pattern: GrammarPattern
    var defaultCollectionItem: DefaultCollectionItem

    enum CodingKeys: String, CodingKey {
        case title
        case sourceSentence
        case chineseMeaning
        case analysisScopeNote
        case chunks
        case pattern
        case defaultCollectionItem
    }

    init(
        title: String = "语法解析",
        sourceSentence: String,
        chineseMeaning: String,
        analysisScopeNote: String,
        chunks: [GrammarChunk],
        pattern: GrammarPattern,
        defaultCollectionItem: DefaultCollectionItem
    ) {
        self.title = title
        self.sourceSentence = sourceSentence
        self.chineseMeaning = chineseMeaning
        self.analysisScopeNote = analysisScopeNote
        self.chunks = chunks
        self.pattern = pattern
        self.defaultCollectionItem = defaultCollectionItem
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pattern = try container.decodeIfPresent(GrammarPattern.self, forKey: .pattern)
            ?? GrammarPattern(en: "", zh: "")
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "语法解析"
        self.sourceSentence = try container.decodeIfPresent(String.self, forKey: .sourceSentence) ?? ""
        self.chineseMeaning = try container.decodeIfPresent(String.self, forKey: .chineseMeaning) ?? ""
        self.analysisScopeNote = try container.decodeIfPresent(String.self, forKey: .analysisScopeNote) ?? ""
        self.chunks = try container.decodeIfPresent([GrammarChunk].self, forKey: .chunks) ?? []
        self.pattern = pattern
        self.defaultCollectionItem = try container.decodeIfPresent(DefaultCollectionItem.self, forKey: .defaultCollectionItem)
            ?? DefaultCollectionItem(title: pattern.en, note: pattern.zh, type: "句型")
    }

    static func recovery(sourceText: String) -> GrammarSpineCompletion {
        let source = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let chunks = GrammarResult.recoveryChunks(for: source)
        let patternText: String
        let patternZh: String
        if source.contains(":") {
            patternText = "Main clause: explanation clauses"
            patternZh = "主句：后面用多个分句解释或展开"
        } else if source.range(of: ", but ", options: [.caseInsensitive]) != nil {
            patternText = "Passive main clause, but coordinated passive clauses"
            patternZh = "被动主句后接转折并列被动分句"
        } else if source.contains(";"),
                  source.range(of: " so ", options: [.caseInsensitive]) != nil,
                  source.range(of: " that ", options: [.caseInsensitive]) != nil {
            patternText = "As-clause + main clause; so ... that result clause"
            patternZh = "as 时间从句 + 主句；so ... that 结果分句"
        } else if source.range(of: " is that ", options: [.caseInsensitive]) != nil {
            patternText = "S is that when-clause, content clause"
            patternZh = "主语 + is that 内容从句，内含 when 时间从句"
        } else if source.range(of: " believes that ", options: [.caseInsensitive]) != nil {
            patternText = "S believes that once-clause, purpose clause"
            patternZh = "主语 + believes that 宾语从句，内含 once 条件和目的状语"
        } else {
            patternText = "S + V + complements/modifiers"
            patternZh = "主语 + 谓语 + 补足/修饰成分"
        }
        return GrammarSpineCompletion(
            sourceSentence: source,
            chineseMeaning: "该长句包含多个分句；已先恢复语法骨架，完整细节可重试补全。",
            analysisScopeNote: "AI 首次返回未形成可解析 JSON，Lingobar 先显示可恢复的语法骨架。",
            chunks: chunks,
            pattern: GrammarPattern(en: patternText, zh: patternZh),
            defaultCollectionItem: DefaultCollectionItem(title: patternText, note: patternZh, type: "句型")
        )
    }
}

private struct GrammarTokensCompletion: Decodable, Sendable {
    var chunks: [ChunkTokens]

    enum CodingKeys: String, CodingKey {
        case chunks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chunks = try container.decodeIfPresent([ChunkTokens].self, forKey: .chunks) ?? []
    }

    struct ChunkTokens: Decodable, Sendable {
        var id: String
        var tokens: [GrammarToken]

        enum CodingKeys: String, CodingKey {
            case id
            case tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeLossyStringIfPresent(forKey: .id) ?? ""
            self.tokens = try container.decodeIfPresent([GrammarToken].self, forKey: .tokens) ?? []
        }
    }
}

private struct GrammarDependenciesTreeCompletion: Decodable, Sendable {
    var dependencies: [GrammarDependency]
    var tree: GrammarTreeNode

    enum CodingKeys: String, CodingKey {
        case dependencies
        case tree
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dependencies = try container.decodeIfPresent([GrammarDependency].self, forKey: .dependencies) ?? []
        self.tree = try container.decodeIfPresent(GrammarTreeNode.self, forKey: .tree)
            ?? GrammarTreeNode(label: "主句", role: .predicate, text: "")
    }
}

private struct GrammarTrunkOrderCompletion: Decodable, Sendable {
    var trunk: GrammarTrunk
    var wordOrder: GrammarWordOrder

    enum CodingKeys: String, CodingKey {
        case trunk
        case wordOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.trunk = try container.decodeIfPresent(GrammarTrunk.self, forKey: .trunk)
            ?? GrammarTrunk(core: [], dropped: [], coreZh: "")
        self.wordOrder = try container.decodeIfPresent(GrammarWordOrder.self, forKey: .wordOrder)
            ?? GrammarWordOrder(en: [], zhOrder: [], zhText: [], note: "")
    }
}

private struct GrammarTenseVoiceCompletion: Decodable, Sendable {
    var tenseVoice: [GrammarTenseClause]

    enum CodingKeys: String, CodingKey {
        case tenseVoice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tenseVoice = try container.decodeIfPresent([GrammarTenseClause].self, forKey: .tenseVoice) ?? []
    }
}

private struct GrammarKnowledgeCompletion: Decodable, Sendable {
    var collocations: [GrammarCollocation]
    var phrases: [GrammarPhrase]
    var grammarPoints: [GrammarPoint]

    enum CodingKeys: String, CodingKey {
        case collocations
        case phrases
        case grammarPoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.collocations = try container.decodeIfPresent([GrammarCollocation].self, forKey: .collocations) ?? []
        self.phrases = try container.decodeIfPresent([GrammarPhrase].self, forKey: .phrases) ?? []
        self.grammarPoints = try container.decodeIfPresent([GrammarPoint].self, forKey: .grammarPoints) ?? []
    }
}

private struct GrammarCanonicalParse: Encodable {
    var sourceSentence: String
    var chunks: [GrammarCanonicalChunk]
    var pattern: GrammarPattern
}

private struct GrammarCanonicalChunk: Encodable {
    var id: String
    var role: GrammarRole
    var text: String
    var label: String
    var note: String
}

@MainActor
final class LingobarViewModel: ObservableObject {
    private static let defaultExampleSelection = "any sentence can become a small object for translation, parsing, memory, and expression."

    @Published var mode: LingobarMode = .selection
    @Published var action: LingobarActionDescriptor = LingobarActionDescriptor(builtInAction: .translate)
    @Published var selectedText = defaultExampleSelection
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
    @Published var isResultStale = false
    @Published var recentCollectedPhraseID: UUID?
    @Published var isFollowUpOpen = false
    @Published var isFollowUpContextAnchored = true
    @Published var followUpDraft = ""
    @Published var followUpThread: [LingobarFollowUpExchange] = []
    @Published var followUpQuestion = ""
    @Published var followUpAnswer = ""
    @Published var followUpKey: LingobarFollowUpKey?
    @Published var isFollowUpLoading = false
    @Published private(set) var sharedLearningInsights: LingobarLearningInsights = .empty
    var onLayoutChanged: (() -> Void)?

    @Published var actions: [LingobarActionDescriptor] = AppSettings.actionDescriptors
    private let store: PhraseStore
    private let historyStore: LingobarHistoryStore
    private var currentHistoryRecord: LingobarHistoryRecord?
    private var activeResultSnapshots: [String: LingobarStoredResultSnapshot] = [:]
    private var activeAIRequestID = UUID()
    private var grammarResultCache: [GrammarRequestKey: GrammarResult] = [:]
    private var grammarCacheKeys: [GrammarRequestKey] = []
    private var grammarRequests: [GrammarRequestKey: Task<GrammarResult, Error>] = [:]
    private let grammarCacheLimit = 6
    private var sharedLearningInsightsKey: GrammarRequestKey?
    private var activeFollowUpRequestID = UUID()
    private var activeFollowUpExchangeID: UUID?
    private var followUpRevealTask: Task<Void, Never>?

    init(store: PhraseStore = .defaultStore(), historyStore: LingobarHistoryStore = .defaultStore()) {
        self.store = store
        self.historyStore = historyStore
        self.savedPhrases = (try? store.load()) ?? [
            SavedPhrase(title: "selection-first", note: "以选区为入口，而不是先打开 App。")
        ]

        self.result = LingobarViewModel.pendingResult(
            for: LingobarActionDescriptor(builtInAction: .translate),
            actionDescriptors: AppSettings.actionDescriptors
        )
    }

    func present(selection: String?, sourceAppName: String = "当前 App", requestedActionID: String? = nil) {
        actions = AppSettings.actionDescriptors
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        recentCollectedPhraseID = nil
        isResultStale = false
        resetSharedLearningInsights()
        resetFollowUpSession(sendsLayoutChange: false)

        if let selection, !selection.isEmpty {
            mode = .selection
            selectionSource = sourceAppName
            selectedText = selection
            action = requestedActionID.flatMap(actionDescriptor(for:)) ?? configuredDefaultSelectionAction(for: selection)
            result = pendingResult(for: action)
            grammarResult = nil
            showsResult = true
            loadingStartedAt = nil
            onLayoutChanged?()
            guard action.isAvailable(for: activeText) else {
                showUnavailableAction(action)
                return
            }
            runAIIfAvailable(for: action, text: activeText)
        } else {
            mode = .input
            action = actionDescriptor(for: requestedActionID ?? LanguageAction.rewrite.actionID)
                ?? LingobarActionDescriptor(builtInAction: .rewrite)
            inputText = AppSettings.autoReadClipboard ? clipboardText() : ""
            result = pendingResult(for: action)
            grammarResult = nil
            showsResult = false
            status = "AI 就绪"
            loadingStartedAt = nil
            onLayoutChanged?()
        }
    }

    func presentInputMode() {
        present(selection: nil, sourceAppName: "输入模式", requestedActionID: LanguageAction.rewrite.actionID)
    }

    func presentSelectionLauncher(selection: String, sourceAppName: String = "当前 App") {
        actions = AppSettings.actionDescriptors
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        recentCollectedPhraseID = nil
        isResultStale = false
        resetSharedLearningInsights()
        resetFollowUpSession(sendsLayoutChange: false)
        mode = .launcher
        selectionSource = sourceAppName
        selectedText = selection
        showsResult = false
        isLoading = false
        loadingStartedAt = nil
        status = "选择动作"
        onLayoutChanged?()
    }

    func presentRecentSelectionHistoryOrExample(sourceAppName: String = "Lingobar") {
        actions = AppSettings.actionDescriptors
        if let record = recentSelectionHistoryRecord() {
            let snapshot = record.storedSnapshot(for: record.actionID)
                ?? LingobarStoredResultSnapshot(result: record.resultSnapshot)
            presentSnapshot(
                sourceText: record.sourceText,
                sourceAppName: record.sourceAppName,
                sourceAction: record.action,
                sourceActionID: record.actionID,
                resultSnapshot: snapshot.result,
                grammarSnapshot: snapshot.grammarResult,
                resultSnapshots: record.resultSnapshots
            )
            currentHistoryRecord = record
            status = "最近选择历史"
            return
        }

        present(
            selection: Self.defaultExampleSelection,
            sourceAppName: sourceAppName,
            requestedActionID: AppSettings.defaultEnglishActionID
        )
        status = "示例文本"
    }

    var launcherActions: [LingobarActionDescriptor] {
        Array(actions.filter(\.isResultProducing).prefix(5))
    }

    func openFromLauncher(_ descriptor: LingobarActionDescriptor) {
        mode = .selection
        action = descriptor
        result = pendingResult(for: descriptor)
        grammarResult = nil
        showsResult = true
        isResultStale = false
        onLayoutChanged?()
        guard descriptor.isAvailable(for: activeText) else {
            showUnavailableAction(descriptor)
            return
        }
        runAIIfAvailable(for: descriptor, text: activeText)
    }

    func presentGrammarFixture(sourceAppName: String = "Lingobar") {
        actions = AppSettings.actionDescriptors
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        recentCollectedPhraseID = nil
        resetSharedLearningInsights()
        resetFollowUpSession(sendsLayoutChange: false)
        let grammar = GrammarResult.fixture(id: AppSettings.grammarFixtureID) ?? .mockupFixture
        mode = .selection
        selectionSource = sourceAppName
        selectedText = grammar.sourceSentence
        action = LingobarActionDescriptor(builtInAction: .grammar)
        grammarResult = grammar
        result = grammar.lingobarResult(shortcut: shortcut(for: action))
        setSharedLearningInsights(from: grammar)
        showsResult = true
        isLoading = false
        loadingStartedAt = nil
        status = "语法 fixture"
        onLayoutChanged?()
    }

    func presentSetupGate(_ setupGateStatus: SetupGateStatus) {
        actions = AppSettings.actionDescriptors
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        recentCollectedPhraseID = nil
        resetSharedLearningInsights()
        resetFollowUpSession(sendsLayoutChange: false)
        mode = .setup
        self.setupGateStatus = setupGateStatus
        showsResult = false
        isLoading = false
        loadingStartedAt = nil
        status = "需要完成设置"
        onLayoutChanged?()
    }

    func perform(_ newAction: LanguageAction) {
        guard let descriptor = actionDescriptor(for: newAction.actionID) else {
            return
        }
        perform(descriptor)
    }

    func perform(_ newAction: LingobarActionDescriptor) {
        guard newAction.isAvailable(for: activeText) else {
            status = "\(newAction.title)仅支持英文内容"
            return
        }

        if newAction.builtInAction == .collect {
            recentCollectedPhraseID = nil
            saveCurrentHistorySnapshot()
            return
        }

        recentCollectedPhraseID = nil
        if !isResultStale, let storedSnapshot = activeResultSnapshots[newAction.id] {
            applyStoredSnapshot(storedSnapshot, action: newAction, status: "已从快照打开")
            return
        }

        action = newAction
        grammarResult = nil
        currentHistoryRecord = nil
        isResultStale = false

        switch newAction.builtInAction {
        case .copy:
            copyResult()
        case .translate, .grammar, .rewrite, .examples, .pronounce, nil:
            result = pendingResult(for: newAction)
            showsResult = true
            onLayoutChanged?()
            runAIIfAvailable(for: newAction, text: activeText)
        case .collect:
            break
        }
    }

    func submitInput() {
        mode = .input
        let submittedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedText.isEmpty else {
            status = "请输入内容"
            return
        }
        inputText = submittedText
        activeAIRequestID = UUID()
        activeResultSnapshots = [:]
        currentHistoryRecord = nil
        grammarResult = nil
        recentCollectedPhraseID = nil
        resetSharedLearningInsights()
        resetFollowUpThread()
        perform(action)
    }

    func selectInputAction(_ descriptor: LingobarActionDescriptor) {
        guard mode == .input,
              descriptor.isResultProducing else {
            return
        }
        action = descriptor
        result = pendingResult(for: descriptor)
        showsResult = false
        grammarResult = nil
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        status = "已选择\(descriptor.title)"
    }

    func updateSelectedText(_ text: String) {
        guard selectedText != text else {
            return
        }
        selectedText = text
        guard mode == .selection else {
            return
        }
        activeAIRequestID = UUID()
        currentHistoryRecord = nil
        activeResultSnapshots = [:]
        grammarResult = nil
        isResultStale = showsResult
        resetSharedLearningInsights()
        resetFollowUpThread()
        if isResultStale {
            status = "原文已修改"
        }
        onLayoutChanged?()
    }

    func regenerateCurrentAction() {
        perform(action)
    }

    func isAvailable(_ languageAction: LingobarActionDescriptor) -> Bool {
        languageAction.isAvailable(for: activeText)
    }

    func isActionHighlighted(_ languageAction: LingobarActionDescriptor) -> Bool {
        if languageAction.builtInAction == .collect {
            return currentHistoryRecord?.isSaved == true
        }
        return action == languageAction
    }

    func togglePinned() {
        isPinned.toggle()
        status = isPinned ? "已固定" : "已取消固定"
    }

    var canUseFollowUp: Bool {
        mode != .setup &&
            !activeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            showsResult &&
            !isLoading
    }

    var visibleLearningInsights: LingobarLearningInsights {
        sharedLearningInsights
    }

    var hasFollowUpExchange: Bool {
        !followUpThread.isEmpty
    }

    var followUpContextKind: String {
        if isFollowUpContextAnchored {
            "\(action.title)结果"
        } else {
            "自由提问"
        }
    }

    var followUpContextText: String {
        if isFollowUpContextAnchored {
            let text = activeText.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? result.title : text
        }
        return "未锚定上下文"
    }

    var followUpSuggestions: [String] {
        switch action.builtInAction {
        case .grammar:
            [
                "这句最容易读错的是哪一层？",
                "这里为什么这样拆？",
                "帮我把这句改得更口语"
            ]
        case .rewrite:
            [
                "这个版本还能更自然吗？",
                "帮我改得更正式一点",
                "解释一下为什么这样改"
            ]
        case .translate:
            [
                "这句话还有更自然的译法吗？",
                "这里的关键词怎么用？",
                "帮我举一个类似例句"
            ]
        case .examples:
            [
                "哪一句最适合邮件里用？",
                "帮我换一个更口语的场景",
                "解释一下这些例句的语气差别"
            ]
        case .pronounce:
            [
                "这里最该注意哪个重音？",
                "帮我拆一下连读",
                "这个词常见读错点是什么？"
            ]
        case .copy, .collect:
            [
                "这段话还能怎么表达？",
                "帮我解释关键表达",
                "给我一个可复用例句"
            ]
        case nil:
            [
                "这个结果还能换一种说法吗？",
                "帮我解释一下关键表达",
                "给我一个可复用版本"
            ]
        }
    }

    func toggleFollowUpPane() {
        guard canUseFollowUp || isFollowUpOpen else {
            status = "暂无可追问内容"
            return
        }
        if isFollowUpOpen {
            closeFollowUp()
        } else {
            isFollowUpOpen = true
            if !hasFollowUpExchange {
                isFollowUpContextAnchored = true
            }
            status = "追问已打开"
            onLayoutChanged?()
        }
    }

    func closeFollowUp(sendsLayoutChange: Bool = true) {
        let wasOpen = isFollowUpOpen
        isFollowUpOpen = false
        if wasOpen, sendsLayoutChange {
            onLayoutChanged?()
        }
    }

    func toggleFollowUpContextAnchor() {
        isFollowUpContextAnchored.toggle()
        status = isFollowUpContextAnchored ? "已锚定上下文" : "已取消锚定"
    }

    func submitFollowUp(_ overrideQuestion: String? = nil) {
        let question = (overrideQuestion ?? followUpDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            status = "请输入追问"
            return
        }
        guard !isFollowUpLoading else {
            status = "追问生成中"
            return
        }
        guard canUseFollowUp else {
            status = "暂无可追问内容"
            return
        }
        guard let aiClient = AppSettings.makeAIClient() else {
            appendFollowUpExchange(
                LingobarFollowUpExchange(
                    question: question,
                    answer: "请先完成 AI 设置后再追问。"
                )
            )
            followUpDraft = ""
            isFollowUpLoading = false
            status = "需要 AI 设置"
            return
        }

        let context = followUpContextSnapshot()
        let exchangeID = appendFollowUpExchange(
            LingobarFollowUpExchange(
                question: question,
                isLoading: true
            )
        )
        followUpDraft = ""
        isFollowUpLoading = true
        status = "追问生成中"
        let requestID = UUID()
        activeFollowUpRequestID = requestID
        activeFollowUpExchangeID = exchangeID

        let completionTask = Task.detached(priority: .userInitiated) {
            try await LingobarFollowUpCompletionDecoder.decode(
                aiClient: aiClient,
                context: context,
                question: question
            )
        }
        Task {
            do {
                let completion = try await completionTask.value
                completeFollowUp(completion, requestID: requestID)
            } catch {
                failFollowUp(error, requestID: requestID)
            }
        }
    }

    func copyFollowUpAnswer(exchangeID: UUID? = nil) {
        let exchange = followUpExchange(for: exchangeID)
        let answer = (exchange?.answer ?? followUpAnswer).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            return
        }
        recentCollectedPhraseID = nil
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(answer, forType: .string)
        status = "已复制追问回答"
    }

    @discardableResult
    func collectFollowUpAnswer(exchangeID: UUID? = nil) -> UUID? {
        let exchange = followUpExchange(for: exchangeID)
        let answer = (exchange?.answer ?? followUpAnswer).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            return nil
        }
        let question = exchange?.question ?? followUpQuestion
        let key = exchange?.key ?? followUpKey
        return collectFragment(
            LingobarCollectionFragment(
                title: key?.term ?? String(answer.prefix(42)),
                note: "追问回答",
                type: key == nil ? "文本" : "短语",
                rows: [
                    LingobarRow("问题", question),
                    LingobarRow("回答", answer)
                ]
            )
        )
    }

    @discardableResult
    func saveCurrentPhrase() -> UUID? {
        let collectionTitle: String
        let note: String
        let type: String
        if AppSettings.collectionTarget == .originalSelection {
            collectionTitle = activeText
            note = "来自原文"
            type = "文本"
        } else {
            collectionTitle = result.defaultCollectionItem?.title ?? (result.defaultCollectionTitle.isEmpty ? activeText : result.defaultCollectionTitle)
            note = result.defaultCollectionItem?.note ?? result.summary
            type = result.defaultCollectionItem?.type ?? "文本"
        }
        return collectFragment(
            LingobarCollectionFragment(
                title: collectionTitle,
                note: note,
                type: type,
                rows: result.rows
            )
        )
    }

    @discardableResult
    func collectFragment(_ fragment: LingobarCollectionFragment) -> UUID? {
        let title = phraseTitle(from: fragment.title)
        guard !title.isEmpty else {
            return nil
        }
        let summary = fragment.note.isEmpty ? fragment.title : fragment.note
        let snapshotRows = fragment.rows.isEmpty
            ? [LingobarRow(fragment.type, fragment.title)]
            : fragment.rows
        let snapshot = LingobarResult(
            title: action.title,
            shortcut: shortcut(for: action),
            summary: summary,
            rows: snapshotRows,
            sideTitle: "后续动作",
            chips: [],
            moreActionTitle: action.moreActionTitle,
            defaultCollectionItem: DefaultCollectionItem(
                title: fragment.title,
                note: fragment.note,
                type: fragment.type
            )
        )
        let phrase = SavedPhrase(
            title: title,
            note: fragment.note,
            type: fragment.type.isEmpty ? "文本" : fragment.type,
            sourceText: activeText,
            sourceAppName: activeSourceAppName,
            sourceAction: action.builtInAction,
            resultSnapshot: snapshot
        )
        savedPhrases.insert(phrase, at: 0)
        try? store.save(savedPhrases)
        recentCollectedPhraseID = phrase.id
        status = "已收藏"
        return phrase.id
    }

    func saveCurrentHistorySnapshot() {
        guard let record = currentHistoryRecord ?? LingobarHistoryRecord.make(
            action: action,
            sourceText: activeText,
            sourceAppName: activeSourceAppName,
            result: result
        ) else {
            recentCollectedPhraseID = nil
            status = "暂无可保存内容"
            return
        }
        recentCollectedPhraseID = nil
        var savedRecord = record
        savedRecord.isSaved = true
        if !activeResultSnapshots.isEmpty {
            savedRecord.resultSnapshots.merge(activeResultSnapshots) { _, new in new }
        }
        do {
            let savedRecords = try historyStore.saveOrAppend(savedRecord)
            currentHistoryRecord = savedRecords.first { record in
                record.id == savedRecord.id || record.sourceText == savedRecord.sourceText
            } ?? savedRecord
            status = "已保存"
        } catch {
            currentHistoryRecord = savedRecord
            status = "保存失败"
        }
    }

    func copyResult() {
        recentCollectedPhraseID = nil
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.summary, forType: .string)
        status = "已复制"
    }

    func copyInlineSelection(_ text: String) {
        let selectedText = normalizedInlineSelection(text)
        guard !selectedText.isEmpty else {
            return
        }
        recentCollectedPhraseID = nil
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
        status = "已复制选中文本"
    }

    private func configuredDefaultSelectionAction(for selection: String) -> LingobarActionDescriptor {
        let builtInDefault = LanguageAction.defaultSelectionAction(for: selection)
        let configuredID = builtInDefault == .rewrite
            ? AppSettings.defaultChineseMixedActionID
            : AppSettings.defaultEnglishActionID
        let configured = actionDescriptor(for: configuredID)
        if let configured {
            return configured
        }
        return actionDescriptor(for: builtInDefault.actionID)
            ?? LingobarActionDescriptor(builtInAction: builtInDefault)
    }

    private func actionDescriptor(for actionID: String?) -> LingobarActionDescriptor? {
        guard let actionID,
              !actionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        if let descriptor = actions.first(where: { $0.id == actionID }) {
            return descriptor
        }
        return AppSettings.actionDescriptors.first { $0.id == actionID }
    }

    private func showUnavailableAction(_ unavailableAction: LingobarActionDescriptor) {
        action = unavailableAction
        grammarResult = nil
        result = errorResult(message: "\(unavailableAction.title)暂不支持当前文本。")
        showsResult = true
        isLoading = false
        loadingStartedAt = nil
        status = "\(unavailableAction.title)不适用"
        onLayoutChanged?()
    }

    private func recentSelectionHistoryRecord() -> LingobarHistoryRecord? {
        guard let records = try? historyStore.load() else {
            return nil
        }
        return records.first { record in
            !record.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                record.sourceAppName != "输入模式"
        }
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

    func presentSnapshot(
        sourceText: String,
        sourceAppName: String,
        sourceAction: LanguageAction?,
        sourceActionID: String? = nil,
        resultSnapshot: LingobarResult,
        grammarSnapshot: GrammarResult? = nil,
        resultSnapshots: [String: LingobarStoredResultSnapshot] = [:]
    ) {
        actions = AppSettings.actionDescriptors
        activeAIRequestID = UUID()
        resetSharedLearningInsights()
        resetFollowUpSession(sendsLayoutChange: false)
        mode = .selection
        selectionSource = sourceAppName.isEmpty ? "Lingobar" : sourceAppName
        selectedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        action = actionDescriptor(for: sourceActionID)
            ?? sourceAction.flatMap { actionDescriptor(for: $0.actionID) }
            ?? configuredDefaultSelectionAction(for: selectedText)
        var snapshots = resultSnapshots
        snapshots[action.id] = LingobarStoredResultSnapshot(
            result: resultSnapshot,
            grammarResult: grammarSnapshot ?? resultSnapshots[action.id]?.grammarResult
        )
        activeResultSnapshots = snapshots
        recentCollectedPhraseID = nil
        grammarResult = action.builtInAction == .grammar ? activeResultSnapshots[action.id]?.grammarResult : nil
        if let grammarSnapshot = grammarSnapshot ?? activeResultSnapshots[LanguageAction.grammar.actionID]?.grammarResult {
            setSharedLearningInsights(from: grammarSnapshot)
        }
        result = resultSnapshot
        showsResult = true
        isLoading = false
        loadingStartedAt = nil
        currentHistoryRecord = nil
        status = "已从快照打开"
        onLayoutChanged?()
    }

    private func applyStoredSnapshot(
        _ snapshot: LingobarStoredResultSnapshot,
        action newAction: LingobarActionDescriptor,
        status message: String
    ) {
        activeAIRequestID = UUID()
        action = newAction
        grammarResult = newAction.builtInAction == .grammar ? snapshot.grammarResult : nil
        result = snapshot.result
        showsResult = true
        isLoading = false
        loadingStartedAt = nil
        status = message
        onLayoutChanged?()
    }

    @discardableResult
    func collectInlineSelection(_ text: String) -> UUID? {
        let selectedText = normalizedInlineSelection(text)
        guard !selectedText.isEmpty else {
            return nil
        }
        return collectFragment(
            LingobarCollectionFragment(
                title: selectedText,
                note: "来自 \(result.title) 内容区选中文本",
                type: "文本",
                rows: [LingobarRow("选中文本", selectedText)]
            )
        )
    }

    func insertResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.summary, forType: .string)
        status = "Ready to paste"
    }

    private var activeText: String {
        mode == .input ? inputText : selectedText
    }

    private var activeSourceAppName: String {
        mode == .input ? "输入模式" : selectionSource
    }

    private func resetFollowUpSession(sendsLayoutChange: Bool = true) {
        closeFollowUp(sendsLayoutChange: sendsLayoutChange)
        resetFollowUpThread()
    }

    private func resetFollowUpThread() {
        followUpRevealTask?.cancel()
        followUpRevealTask = nil
        activeFollowUpRequestID = UUID()
        activeFollowUpExchangeID = nil
        followUpDraft = ""
        followUpThread = []
        followUpQuestion = ""
        followUpAnswer = ""
        followUpKey = nil
        isFollowUpLoading = false
    }

    private func followUpContextSnapshot() -> LingobarFollowUpContextSnapshot {
        LingobarFollowUpContextSnapshot(
            isAnchored: isFollowUpContextAnchored,
            mode: mode,
            actionTitle: action.title,
            sourceText: activeText,
            resultTitle: result.title,
            resultSummary: result.summary,
            resultRows: result.rows,
            conversation: followUpConversationContext()
        )
    }

    private func completeFollowUp(_ completion: LingobarFollowUpCompletion, requestID: UUID) {
        guard activeFollowUpRequestID == requestID,
              let exchangeID = activeFollowUpExchangeID else {
            return
        }
        followUpRevealTask?.cancel()
        updateFollowUpExchange(id: exchangeID) { exchange in
            exchange.answer = ""
            exchange.key = nil
            exchange.isLoading = true
        }
        let answer = completion.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        followUpRevealTask = Task { @MainActor in
            for chunk in Self.followUpRevealChunks(from: answer) {
                guard activeFollowUpRequestID == requestID, !Task.isCancelled else {
                    return
                }
                updateFollowUpExchange(id: exchangeID) { exchange in
                    exchange.answer += chunk
                }
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
            guard activeFollowUpRequestID == requestID, !Task.isCancelled else {
                return
            }
            updateFollowUpExchange(id: exchangeID) { exchange in
                exchange.key = completion.key
                exchange.isLoading = false
            }
            isFollowUpLoading = false
            status = "追问完成"
            followUpRevealTask = nil
        }
    }

    private func failFollowUp(_ error: Error, requestID: UUID) {
        guard activeFollowUpRequestID == requestID,
              let exchangeID = activeFollowUpExchangeID else {
            return
        }
        followUpRevealTask?.cancel()
        followUpRevealTask = nil
        updateFollowUpExchange(id: exchangeID) { exchange in
            exchange.answer = error is DecodingError
                ? "AI 返回的追问格式不符合预期，请重试。"
                : userFacingAIErrorMessage(error)
            exchange.key = nil
            exchange.isLoading = false
        }
        isFollowUpLoading = false
        status = "追问失败"
    }

    @discardableResult
    private func appendFollowUpExchange(_ exchange: LingobarFollowUpExchange) -> UUID {
        followUpThread.append(exchange)
        syncLatestFollowUpState(from: exchange)
        return exchange.id
    }

    private func updateFollowUpExchange(
        id: UUID,
        _ transform: (inout LingobarFollowUpExchange) -> Void
    ) {
        guard let index = followUpThread.firstIndex(where: { $0.id == id }) else {
            return
        }
        var exchange = followUpThread[index]
        transform(&exchange)
        followUpThread[index] = exchange
        if followUpThread.last?.id == id {
            syncLatestFollowUpState(from: exchange)
        }
    }

    private func syncLatestFollowUpState(from exchange: LingobarFollowUpExchange) {
        followUpQuestion = exchange.question
        followUpAnswer = exchange.answer
        followUpKey = exchange.key
    }

    private func followUpExchange(for id: UUID?) -> LingobarFollowUpExchange? {
        if let id {
            return followUpThread.first { $0.id == id }
        }
        return followUpThread.last
    }

    private func followUpConversationContext() -> [LingobarFollowUpConversationTurn] {
        followUpThread
            .filter { !$0.isLoading && !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .suffix(6)
            .map {
                LingobarFollowUpConversationTurn(
                    question: $0.question,
                    answer: $0.answer
                )
            }
    }

    private static func followUpRevealChunks(from answer: String) -> [String] {
        var chunks: [String] = []
        var buffer = ""
        for character in answer {
            buffer.append(character)
            if buffer.count >= 2 || character.isWhitespace || "，。！？；：,.!?;:".contains(character) {
                chunks.append(buffer)
                buffer = ""
            }
        }
        if !buffer.isEmpty {
            chunks.append(buffer)
        }
        return chunks
    }

    private func runAIIfAvailable(for action: LingobarActionDescriptor, text: String) {
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
        if action.builtInAction != .grammar {
            warmSharedLearningInsightsIfAvailable(for: text, aiClient: aiClient)
        }

        let grammarKey = action.builtInAction == .grammar
            ? grammarRequestKey(for: text, configuration: aiClient.configuration)
            : nil
        if let grammarKey, let cachedGrammar = grammarResultCache[grammarKey] {
            completeAIRequest(
                .grammar(cachedGrammar),
                action: action,
                requestID: requestID,
                historySourceText: historySourceText,
                historySourceAppName: historySourceAppName,
                grammarCacheKey: grammarKey
            )
            return
        }

        isLoading = true
        loadingStartedAt = Date()
        status = "AI 生成中"
        recordUITestMetric(event: "start", action: action.id, requestID: requestID)
        onLayoutChanged?()

        if let grammarKey {
            let grammarTask = grammarRequests[grammarKey] ?? Task.detached(priority: .userInitiated) {
                try await LingobarAICompletionDecoder.decodeGrammar(
                    aiClient: aiClient,
                    user: text,
                    onSpine: { [weak self] partial in
                        await self?.completeGrammarSpine(
                            partial,
                            action: action,
                            requestID: requestID
                        )
                    }
                )
            }
            grammarRequests[grammarKey] = grammarTask
            Task {
                do {
                    let grammar = try await grammarTask.value
                    grammarRequests[grammarKey] = nil
                    rememberGrammarResult(grammar, for: grammarKey)
                    completeAIRequest(
                        .grammar(grammar),
                        action: action,
                        requestID: requestID,
                        historySourceText: historySourceText,
                        historySourceAppName: historySourceAppName,
                        grammarCacheKey: grammarKey
                    )
                } catch {
                    grammarRequests[grammarKey] = nil
                    failGrammarRequest(error, requestID: requestID)
                }
            }
            return
        }

        let system = systemPrompt(for: action)
        let user = action.customPromptAction?.userPrompt(for: text) ?? text
        let completionTask = Task.detached(priority: .userInitiated) {
            if let builtInAction = action.builtInAction {
                return try await LingobarAICompletionDecoder.decode(
                    action: builtInAction,
                    aiClient: aiClient,
                    system: system,
                    user: user
                )
            }
            return try await LingobarAICompletionDecoder.decodeCustom(
                aiClient: aiClient,
                system: system,
                user: user
            )
        }
        Task {
            do {
                let decoded = try await completionTask.value
                self.completeAIRequest(
                    decoded,
                    action: action,
                    requestID: requestID,
                    historySourceText: historySourceText,
                    historySourceAppName: historySourceAppName,
                    grammarCacheKey: nil
                )
            } catch {
                self.failAIRequest(error, requestID: requestID)
            }
        }
    }

    private func completeGrammarSpine(
        _ grammar: GrammarResult,
        action: LingobarActionDescriptor,
        requestID: UUID
    ) {
        guard activeAIRequestID == requestID else {
            return
        }
        grammarResult = grammar
        result = grammar.lingobarResult(shortcut: shortcut(for: action))
        status = "语法骨架完成"
        showsResult = true
        recordUITestMetric(event: "spine", action: action.id, requestID: requestID)
        onLayoutChanged?()
    }

    private func failGrammarRequest(_ error: Error, requestID: UUID) {
        guard activeAIRequestID == requestID else {
            return
        }

        if grammarResult != nil {
            status = "语法补全失败"
            isLoading = false
            recordUITestMetric(event: "partial_failure", action: .grammar, requestID: requestID, error: error)
            loadingStartedAt = nil
            onLayoutChanged?()
            return
        }

        failAIRequest(error, requestID: requestID)
    }

    private func completeAIRequest(
        _ decoded: LingobarAICompletionResult,
        action: LingobarActionDescriptor,
        requestID: UUID,
        historySourceText: String,
        historySourceAppName: String,
        grammarCacheKey: GrammarRequestKey?
    ) {
        guard activeAIRequestID == requestID else {
            return
        }

        var completedGrammarResult: GrammarResult?
        switch decoded {
        case .grammar(let decodedGrammar):
            let grammar = decodedGrammar
            grammarResult = grammar
            completedGrammarResult = grammar
            result = grammar.lingobarResult(shortcut: shortcut(for: action))
            setSharedLearningInsights(from: grammar, key: grammarCacheKey)
            if let grammarCacheKey {
                rememberGrammarResult(grammar, for: grammarCacheKey)
            }
        case .structured(let structured):
            grammarResult = nil
            result = structured.lingobarResult(shortcut: shortcut(for: action))
        }

        status = "AI 完成"
        isLoading = false
        recordUITestMetric(event: "complete", action: action.id, requestID: requestID)
        loadingStartedAt = nil
        onLayoutChanged?()
        recordCompletedHistory(
            action: action,
            sourceText: historySourceText,
            sourceAppName: historySourceAppName,
            result: result,
            grammarSnapshot: completedGrammarResult
        )
    }

    private func failAIRequest(_ error: Error, requestID: UUID) {
        guard activeAIRequestID == requestID else {
            return
        }

        grammarResult = nil
        if error is DecodingError {
            result = errorResult(message: decodingErrorMessage(for: action))
            status = "格式错误"
        } else {
            result = errorResult(message: userFacingAIErrorMessage(error))
            status = "AI 不可用"
        }
        isLoading = false
        recordUITestMetric(event: "failure", action: action.id, requestID: requestID, error: error)
        loadingStartedAt = nil
        onLayoutChanged?()
    }

    private func recordUITestMetric(
        event: String,
        action: LanguageAction,
        requestID: UUID,
        error: Error? = nil
    ) {
        recordUITestMetric(event: event, action: action.rawValue, requestID: requestID, error: error)
    }

    private func recordUITestMetric(
        event: String,
        action: String,
        requestID: UUID,
        error: Error? = nil
    ) {
        let path = AppSettings.uiTestMetricsPath
        guard !path.isEmpty else {
            return
        }

        let elapsed = loadingStartedAt.map { Date().timeIntervalSince($0) }
        let payload = UITestMetricEvent(
            event: event,
            action: action,
            requestID: requestID.uuidString,
            elapsed: elapsed,
            status: status,
            error: error.map { String(describing: $0) }
        )
        guard let data = try? JSONEncoder().encode(payload),
              var line = String(data: data, encoding: .utf8) else {
            return
        }
        line.append("\n")

        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
            try handle.close()
        } catch {
            // UI metrics are best-effort and must never affect Lingobar behavior.
        }
    }

    private func grammarRequestKey(
        for text: String,
        configuration: AIProviderConfiguration
    ) -> GrammarRequestKey? {
        let sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty,
              let baseURL = configuration.normalizedBaseURL else {
            return nil
        }
        return GrammarRequestKey(
            sourceText: sourceText,
            baseURLString: baseURL.absoluteString,
            model: configuration.normalizedModel
        )
    }

    private func warmSharedLearningInsightsIfAvailable(
        for text: String,
        aiClient: OpenAICompatibleClient
    ) {
        guard mode == .selection,
              LanguageAction.grammar.isAvailable(for: text),
              let grammarKey = grammarRequestKey(for: text, configuration: aiClient.configuration) else {
            return
        }

        if sharedLearningInsightsKey == grammarKey, !sharedLearningInsights.isEmpty {
            return
        }
        sharedLearningInsightsKey = grammarKey

        if let cachedGrammar = grammarResultCache[grammarKey] {
            setSharedLearningInsights(from: cachedGrammar, key: grammarKey)
            return
        }

        let grammarTask = grammarRequests[grammarKey] ?? Task.detached(priority: .utility) {
            try await LingobarAICompletionDecoder.decodeGrammar(
                aiClient: aiClient,
                user: text
            )
        }
        grammarRequests[grammarKey] = grammarTask

        Task {
            do {
                let grammar = try await grammarTask.value
                grammarRequests[grammarKey] = nil
                rememberGrammarResult(grammar, for: grammarKey)
                guard sharedLearningInsightsKey == grammarKey,
                      grammarRequestKey(for: activeText, configuration: aiClient.configuration) == grammarKey else {
                    return
                }
                setSharedLearningInsights(from: grammar, key: grammarKey)
            } catch {
                if sharedLearningInsightsKey == grammarKey {
                    sharedLearningInsightsKey = nil
                }
                grammarRequests[grammarKey] = nil
            }
        }
    }

    private func rememberGrammarResult(_ grammar: GrammarResult, for key: GrammarRequestKey) {
        grammarResultCache[key] = grammar
        grammarCacheKeys.removeAll { $0 == key }
        grammarCacheKeys.append(key)

        while grammarCacheKeys.count > grammarCacheLimit {
            let oldestKey = grammarCacheKeys.removeFirst()
            grammarResultCache.removeValue(forKey: oldestKey)
        }

        if sharedLearningInsightsKey == key {
            setSharedLearningInsights(from: grammar, key: key)
        }
    }

    private func setSharedLearningInsights(from grammar: GrammarResult, key: GrammarRequestKey? = nil) {
        setSharedLearningInsights(grammar.learningInsights, key: key)
    }

    private func setSharedLearningInsights(_ insights: LingobarLearningInsights, key: GrammarRequestKey? = nil) {
        let insights = LingobarLearningInsights(
            collocations: insights.collocations,
            phrases: insights.phrases,
            grammarPoints: insights.grammarPoints
        )
        if let key {
            sharedLearningInsightsKey = key
        }
        if sharedLearningInsights != insights {
            sharedLearningInsights = insights
        }
        updateCurrentGrammarResultLearningInsights(insights)
    }

    private func updateCurrentGrammarResultLearningInsights(_ insights: LingobarLearningInsights) {
        guard action.builtInAction == .grammar,
              let grammarResult,
              grammarResult.learningInsights != insights else {
            return
        }
        let updatedGrammar = grammarResult.applyingLearningInsights(insights)
        self.grammarResult = updatedGrammar
        result = updatedGrammar.lingobarResult(shortcut: shortcut(for: action))
    }

    private func resetSharedLearningInsights() {
        sharedLearningInsightsKey = nil
        sharedLearningInsights = .empty
    }

    private func recordCompletedHistory(
        action: LingobarActionDescriptor,
        sourceText: String,
        sourceAppName: String,
        result: LingobarResult,
        grammarSnapshot: GrammarResult? = nil
    ) {
        activeResultSnapshots[action.id] = LingobarStoredResultSnapshot(
            result: result,
            grammarResult: grammarSnapshot
        )
        guard var record = LingobarHistoryRecord.make(
            action: action,
            sourceText: sourceText,
            sourceAppName: sourceAppName,
            result: result,
            grammarSnapshot: grammarSnapshot
        ) else {
            return
        }
        record.resultSnapshots.merge(activeResultSnapshots) { _, new in new }
        if let records = try? historyStore.append(record),
           let mergedRecord = records.first(where: { $0.sourceText == record.sourceText || $0.id == record.id }) {
            currentHistoryRecord = mergedRecord
        } else {
            currentHistoryRecord = record
        }
    }

    private func systemPrompt(for action: LingobarActionDescriptor) -> String {
        let schema = """
        Return ONLY JSON with this schema:
        {"title":"\(action.title)","summary":"...","rows":[{"label":"...","value":"..."}],"chips":["..."],"moreActionTitle":"\(action.moreActionTitle)","defaultCollectionItem":{"title":"...","note":"...","type":"短语|英文|例句|句型|文本"}}
        Do not include learningInsights here. 固定搭配, 常见词组, and 语法点 are shared from the cached grammar result so every action tab shows the same learning sections.
        """
        if let customPromptAction = action.customPromptAction {
            return """
            You are Lingobar, a concise bilingual English learning assistant. The UI language is Simplified Chinese.
            Follow the user's saved instruction exactly while preserving the source text's meaning unless the instruction explicitly asks otherwise.
            Saved action title: \(customPromptAction.title)
            \(schema)
            """
        }

        return switch action.builtInAction {
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
            """
            You are Lingobar, a precise English rewriting assistant.
            Rewrite the user's text into natural English. Preserve the user's meaning; do not answer the user's question, evaluate their idea, add new advice, or translate into Chinese.
            Output language rules:
            - summary, every rows[].value, and defaultCollectionItem.title MUST be English-only.
            - Do not include Chinese characters in summary, rows[].value, or defaultCollectionItem.title.
            - UI labels may be Chinese.
            For rows, return these labels exactly and in order:
            1. 主要版本: the best natural English rewrite.
            2. 随意: a casual version.
            3. 正式: a formal version.
            4. 简洁: a concise version.
            5. 地道: an idiomatic version.
            \(schema)
            """
        case .grammar:
            "Grammar uses staged prompts in LingobarAICompletionDecoder."
        case .examples:
            "You are Lingobar. Produce 3 to 5 reusable English examples and avoid long explanations. \(schema)"
        case .pronounce:
            "You are Lingobar. Provide pronunciation guidance: stress, linking, and common mistakes. \(schema)"
        case .copy, .collect, nil:
            "You are Lingobar, a concise bilingual English learning assistant. \(schema)"
        }
    }

    private func errorResult(message: String) -> LingobarResult {
        LingobarResult(
            title: "出错",
            shortcut: shortcut(for: action),
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

    private func decodingErrorMessage(for action: LingobarActionDescriptor) -> String {
        if action.builtInAction == .grammar {
            return "AI 返回结构不符合语法面板，请重试。"
        }
        return "AI 返回结构不符合\(action.title)结果，请重试。"
    }

    func shortcut(for action: LingobarActionDescriptor) -> String {
        LingobarActionCatalog.shortcut(for: action, in: actions)
    }

    private func pendingResult(for action: LingobarActionDescriptor) -> LingobarResult {
        Self.pendingResult(for: action, actionDescriptors: actions)
    }

    private static func pendingResult(
        for action: LingobarActionDescriptor,
        actionDescriptors: [LingobarActionDescriptor]
    ) -> LingobarResult {
        LingobarResult(
            title: action.title,
            shortcut: LingobarActionCatalog.shortcut(for: action, in: actionDescriptors),
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

private struct UITestMetricEvent: Encodable {
    var event: String
    var action: String
    var requestID: String
    var elapsed: TimeInterval?
    var status: String
    var error: String?
    var recordedAt = Date()
}
