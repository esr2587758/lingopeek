import Foundation
import LingobarCore

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw CheckFailure.failed(message)
    }
}

func checkLocalLanguageEngine() throws {
    let engine = LocalLanguageEngine()

    try check(
        LanguageAction.selectionActions.map(\.title) == ["翻译", "语法", "改写", "例句", "收藏", "发音"],
        "selection actions should use canonical Lingobar order and vocabulary"
    )
    try check(
        LanguageAction.selectionActions.map(\.id) == ["translate", "grammar", "rewrite", "examples", "collect", "pronounce"],
        "selection action IDs should use canonical Lingobar semantics"
    )
    try check(
        LanguageAction.defaultSelectionAction(for: "The findings call into question old assumptions.") == .translate,
        "English selection should default to 翻译"
    )
    try check(
        LanguageAction.defaultSelectionAction(for: "我觉得这个方案风险有点高") == .rewrite,
        "Chinese selection should default to 改写"
    )
    try check(
        LanguageAction.defaultSelectionAction(for: "这个方案 feels risky") == .rewrite,
        "Mixed-language selection should default to 改写"
    )
    try check(
        LanguageAction.grammar.isAvailable(for: "The findings call into question old assumptions."),
        "语法 should be available for English selections"
    )
    try check(
        !LanguageAction.grammar.isAvailable(for: "我觉得这个方案风险有点高"),
        "语法 should be disabled for Chinese selections"
    )
    try check(
        !LanguageAction.grammar.isAvailable(for: "这个方案 feels risky"),
        "语法 should be disabled for mixed-language selections"
    )

    let translate = engine.result(for: .translate, text: "any sentence can become a small object")
    try check(translate.title == "翻译", "translate title should match")
    try check(translate.rows.contains { $0.label == "通用" }, "translate should include a general translation")
    try check(translate.rows.contains { $0.label == "书面" }, "translate should include a written translation")
    try check(translate.rows.contains { $0.label == "意译" }, "translate should include a free translation")
    try check(translate.moreActionTitle == "解释更多", "translate more action should be contextual")

    try check(engine.result(for: .grammar, text: "The findings call into question old assumptions.").title == "语法", "grammar title should match")
    try check(engine.result(for: .rewrite, text: "我觉得这个方案风险有点高").title == "改写", "rewrite title should match")
    try check(engine.result(for: .collect, text: "call into question").title == "收藏", "collect title should match")

    try check(engine.result(for: .grammar, text: "The findings call into question old assumptions.").moreActionTitle == "继续拆解", "grammar more action should be contextual")
    try check(engine.result(for: .rewrite, text: "我觉得这个方案风险有点高").moreActionTitle == "更多版本", "rewrite more action should be contextual")
    try check(engine.result(for: .examples, text: "call into question").moreActionTitle == "更多例句", "examples more action should be contextual")
    try check(engine.result(for: .pronounce, text: "consolidate").moreActionTitle == "慢速播放", "pronunciation more action should be contextual")
    try check(translate.defaultCollectionTitle.contains("质疑"), "translation should collect a reusable translation")
    try check(engine.result(for: .grammar, text: "any sentence can become a small object").defaultCollectionTitle.contains("sth."), "grammar should collect its reusable pattern")
    try check(engine.result(for: .rewrite, text: "选中即理解，输入即改写").defaultCollectionTitle.contains("These results"), "rewrite should collect its primary rewrite")
    try check(engine.result(for: .examples, text: "call into question").defaultCollectionTitle.contains("The report"), "examples should collect the first reusable example")

    let rewrite = engine.result(for: .rewrite, text: "选中即理解，输入即改写")
    try check(rewrite.title == "改写", "rewrite title should match")
    try check(rewrite.summary.contains("These results"), "rewrite summary should match the prototype content shape")
    try check(rewrite.shortcut == "⌘3", "rewrite shortcut should be ⌘3")
}

func checkLanguageActionKeyboardShortcuts() throws {
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "1", command: true) == .translate,
        "⌘1 should trigger translate"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "2", command: true) == .grammar,
        "⌘2 should trigger grammar"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "3", command: true) == .rewrite,
        "⌘3 should trigger rewrite"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "4", command: true) == .examples,
        "⌘4 should trigger examples"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "S", command: true) == .collect,
        "⌘S should trigger collect"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "P", command: true) == .pronounce,
        "⌘P should trigger pronounce"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "1", command: false) == nil,
        "bare 1 should not trigger a Lingobar action"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "1", command: true, option: true) == nil,
        "⌥⌘1 should not trigger the ⌘1 action"
    )
}

func checkDeepSeekRequestFactory() throws {
    let request = try DeepSeekRequestFactory.request(
        baseURL: URL(string: "https://api.deepseek.com")!,
        apiKey: "test-key",
        model: "deepseek-v4-flash",
        system: "system prompt",
        user: "hello"
    )

    try check(request.url?.absoluteString == "https://api.deepseek.com/chat/completions", "endpoint should be OpenAI-compatible")
    try check(request.httpMethod == "POST", "request should use POST")
    try check(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key", "authorization header should use bearer token")
    try check(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "content type should be JSON")

    guard let body = request.httpBody else {
        throw CheckFailure.failed("request should have an HTTP body")
    }
    let decoded = try JSONDecoder().decode(DeepSeekChatRequest.self, from: body)
    try check(decoded.model == "deepseek-v4-flash", "request should keep configured model")
    try check(decoded.messages.map(\.role) == ["system", "user"], "request should include system and user messages")
    try check(decoded.messages.last?.content == "hello", "request should keep user content")
    try check(decoded.responseFormat?.type == "json_object", "request should ask provider for JSON object output")
    try check(decoded.maxTokens == 4096, "request should reserve enough tokens for structured JSON")
    try check(!decoded.stream, "request should be non-streaming")
}

func checkOpenAICompatibleRequestFactory() throws {
    let configuration = AIProviderConfiguration(
        apiToken: "test-token",
        baseURLString: "https://api.deepseek.com",
        model: "deepseek-chat"
    )
    let request = try OpenAICompatibleRequestFactory.request(
        configuration: configuration,
        system: "system prompt",
        user: "hello"
    )

    try check(request.url?.absoluteString == "https://api.deepseek.com/chat/completions", "OpenAI-compatible request should use chat completions endpoint")
    try check(request.httpMethod == "POST", "OpenAI-compatible request should use POST")
    try check(request.timeoutInterval == 120, "OpenAI-compatible request should allow long grammar generations")
    try check(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token", "OpenAI-compatible request should use bearer token")
    try check(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "OpenAI-compatible request should send JSON")

    guard let body = request.httpBody else {
        throw CheckFailure.failed("OpenAI-compatible request should have an HTTP body")
    }
    let decoded = try JSONDecoder().decode(OpenAIChatRequest.self, from: body)
    try check(decoded.model == "deepseek-chat", "OpenAI-compatible request should keep configured model")
    try check(decoded.messages.map(\.role) == ["system", "user"], "OpenAI-compatible request should include system and user messages")
    try check(decoded.messages.last?.content == "hello", "OpenAI-compatible request should keep user content")
    try check(decoded.responseFormat?.type == "json_object", "OpenAI-compatible request should ask for JSON object output")
    try check(decoded.maxTokens == 4096, "OpenAI-compatible request should reserve enough tokens for structured JSON")
    try check(!decoded.stream, "OpenAI-compatible request should be non-streaming")
}

func checkSetupGate() throws {
    try check(
        SetupGateStatus(aiAccessConfigured: false, accessibilityPermissionGranted: false).requiredAction == .completeSetup,
        "setup gate should block when AI access and Accessibility are both missing"
    )
    try check(
        SetupGateStatus(aiAccessConfigured: true, accessibilityPermissionGranted: false).requiredAction == .completeSetup,
        "setup gate should block when Accessibility permission is missing"
    )
    try check(
        SetupGateStatus(aiAccessConfigured: false, accessibilityPermissionGranted: true).requiredAction == .completeSetup,
        "setup gate should block when AI access is missing"
    )
    try check(
        SetupGateStatus(aiAccessConfigured: true, accessibilityPermissionGranted: true).requiredAction == .useLingobar,
        "setup gate should allow Lingobar only after all required setup is complete"
    )
}

func checkAIProviderConfiguration() throws {
    try check(
        !AIProviderConfiguration(apiToken: "", baseURLString: "https://api.deepseek.com", model: "deepseek-chat").isUsable,
        "AI provider configuration should require a token"
    )
    try check(
        !AIProviderConfiguration(apiToken: "test-token", baseURLString: "not a url", model: "deepseek-chat").isUsable,
        "AI provider configuration should require a valid base URL"
    )
    try check(
        !AIProviderConfiguration(apiToken: "test-token", baseURLString: "https://api.deepseek.com", model: " ").isUsable,
        "AI provider configuration should require a model"
    )
    let configured = AIProviderConfiguration(
        apiToken: " test-token ",
        baseURLString: " https://api.deepseek.com ",
        model: " deepseek-chat "
    )
    try check(configured.isUsable, "AI provider configuration should be usable when token, base URL, and model are set")
    try check(configured.normalizedBaseURL?.absoluteString == "https://api.deepseek.com", "AI provider configuration should trim base URL")
    try check(configured.normalizedModel == "deepseek-chat", "AI provider configuration should trim model")
}

func checkStructuredAIResultParsing() throws {
    let json = """
    {
      "title": "翻译",
      "summary": "这些发现使人们对长期假设产生了质疑。",
      "rows": [
        { "label": "重点", "value": "call into question = 对……提出质疑" }
      ],
      "chips": ["call into question"],
      "moreActionTitle": "解释更多",
      "defaultCollectionItem": {
        "title": "call into question",
        "note": "对……提出质疑",
        "type": "短语"
      }
    }
    """.data(using: .utf8)!

    let structured = try JSONDecoder().decode(StructuredLingobarResult.self, from: json)
    let result = structured.lingobarResult(shortcut: "⌘1")

    try check(result.title == "翻译", "structured AI result should keep title")
    try check(result.summary.contains("长期假设"), "structured AI result should keep summary")
    try check(result.rows == [LingobarRow("重点", "call into question = 对……提出质疑")], "structured AI result should keep rows")
    try check(result.moreActionTitle == "解释更多", "structured AI result should keep contextual more action")
    try check(result.defaultCollectionItem?.title == "call into question", "structured AI result should keep default collection item")
    try check(result.defaultCollectionTitle == "call into question", "structured AI result should bridge default collection title")

    let invalid = #"{"title":"翻译"}"#.data(using: .utf8)!
    do {
        _ = try JSONDecoder().decode(StructuredLingobarResult.self, from: invalid)
        throw CheckFailure.failed("structured AI result should reject missing required fields")
    } catch is DecodingError {
        // Expected.
    }
}

func checkGrammarResultFixture() throws {
    let fixture = GrammarResult.mockupFixture

    try check(fixture.title == "语法解析", "grammar fixture should use expanded panel title")
    try check(fixture.chunks.count >= 4, "grammar fixture should include phrase-level chunks")
    try check(fixture.chunks.contains { $0.role == .appos }, "grammar fixture should include appositive clause coverage")
    try check(fixture.dependencies.contains { $0.label == "主谓" }, "grammar fixture should include dependency labels")
    try check(!fixture.tree.children.isEmpty, "grammar fixture should include tree children")
    try check(fixture.tenseVoice.contains { $0.voice == "被动" }, "grammar fixture should highlight passive voice")
    try check(fixture.wordOrder.zhOrder == [2, 1, 5, 4, 3], "grammar fixture should capture Chinese reorder mapping")
    try check(fixture.defaultCollectionItem.type == "句型", "grammar should collect a reusable sentence pattern")

    let data = try JSONEncoder().encode(fixture)
    let decoded = try JSONDecoder().decode(GrammarResult.self, from: data)
    try check(decoded == fixture, "grammar fixture should JSON round-trip")

    let bridged = fixture.lingobarResult(shortcut: "⌘2")
    try check(bridged.title == "语法解析", "grammar bridge should use expanded title")
    try check(bridged.defaultCollectionTitle == fixture.pattern.en, "grammar bridge should collect pattern")
    try check(bridged.defaultCollectionItem?.type == "句型", "grammar bridge should preserve collection type")
}

func checkGrammarUITestFixtures() throws {
    try check(GrammarResult.grammarUITestFixtures.count == 2, "grammar UI tests should use two long-sentence fixtures")
    try check(
        GrammarResult.grammarUITestFixtures.map(\.sourceSentence).allSatisfy { $0.split(separator: " ").count >= 20 },
        "grammar UI fixtures should be long difficult sentences"
    )

    for fixture in GrammarResult.grammarUITestFixtures {
        try checkGrammarTabContracts(fixture)
    }

    let policy = GrammarResult.policyIncentivesFixture
    try check(policy.sourceSentence.contains("Although the proposal"), "policy fixture should cover concessive opening")
    try check(policy.chunks.contains { $0.role == .conj && $0.text == "Although" }, "policy fixture should expose although as a conjunction")
    try check(policy.tenseVoice.contains { $0.verb == "was designed" && $0.voice == "被动" }, "policy fixture should cover passive design")
    try check(policy.tenseVoice.contains { $0.verb == "have already invested" && $0.tense == "现在完成时" }, "policy fixture should cover present perfect")
    try check(policy.wordOrder.zhOrder == [1, 3, 2, 4, 5, 6, 8, 7], "policy fixture should capture Chinese relative-clause movement")

    let engineering = GrammarResult.engineeringRedesignFixture
    try check(engineering.sourceSentence.contains("By the time the report was released"), "engineering fixture should cover time-clause opening")
    try check(engineering.tenseVoice.contains { $0.verb == "had already redesigned" && $0.tense == "过去完成时" }, "engineering fixture should cover main past perfect")
    try check(engineering.tenseVoice.contains { $0.verb == "might fail" && $0.mood == "虚拟" }, "engineering fixture should cover modal risk")
    try check(engineering.wordOrder.zhOrder == [1, 3, 2, 4, 6, 5], "engineering fixture should capture Chinese relative-clause movement")
}

func checkGrammarTabContracts(_ fixture: GrammarResult) throws {
    let label = fixture.sourceSentence.prefix(32)
    let chunkIDs = Set(fixture.chunks.map(\.id))

    try check(fixture.title == "语法解析", "\(label): grammar title should be expanded")
    try check(!fixture.sourceSentence.isEmpty, "\(label): source sentence should be present")
    try check(!fixture.chineseMeaning.isEmpty, "\(label): Chinese meaning should be present")

    try check((4...8).contains(fixture.chunks.count), "\(label): annotated tab should use phrase-level chunks")
    try check(chunkIDs.count == fixture.chunks.count, "\(label): annotated tab chunk IDs should be unique")
    try check(fixture.chunks.allSatisfy { !$0.label.isEmpty && !$0.note.isEmpty && !$0.tokens.isEmpty }, "\(label): annotated tab should have labels, notes, and token drilldown")
    try check(fixture.chunks.contains { $0.role == .subject }, "\(label): annotated tab should include a subject")
    try check(fixture.chunks.contains { $0.role == .predicate }, "\(label): annotated tab should include a predicate")
    try check(fixture.chunks.contains { $0.role == .object }, "\(label): annotated tab should include an object")

    try check(!fixture.dependencies.isEmpty, "\(label): dependency tab should include relations")
    try check(
        fixture.dependencies.allSatisfy { chunkIDs.contains($0.from) && chunkIDs.contains($0.to) && !$0.label.isEmpty },
        "\(label): dependency tab should reference valid chunks"
    )
    try check(fixture.dependencies.contains { $0.label == "主谓" }, "\(label): dependency tab should include subject-predicate relation")

    let treeNodes = flattenTree(fixture.tree)
    try check(treeNodes.count >= 8, "\(label): tree tab should include nested clause structure")
    try check(treeNodes.contains { $0.role == .attr }, "\(label): tree tab should expose relative/modifier clauses")
    try check(treeNodes.contains { $0.role == .adv }, "\(label): tree tab should expose adverbial context")

    try check(fixture.trunk.core.count >= 3, "\(label): trunk tab should include S/V/O core")
    try check(fixture.trunk.core.contains { $0.role == .subject }, "\(label): trunk tab should include core subject")
    try check(fixture.trunk.core.contains { $0.role == .predicate }, "\(label): trunk tab should include core predicate")
    try check(fixture.trunk.core.contains { $0.role == .object }, "\(label): trunk tab should include core object")
    try check(!fixture.trunk.dropped.isEmpty && !fixture.trunk.coreZh.isEmpty, "\(label): trunk tab should include dropped modifiers and Chinese core")

    try check(fixture.tenseVoice.count >= 3, "\(label): tense tab should include multiple clauses")
    try check(fixture.tenseVoice.contains { $0.voice == "被动" }, "\(label): tense tab should highlight passive voice")
    try check(
        fixture.tenseVoice.allSatisfy {
            !$0.scope.isEmpty && !$0.verb.isEmpty && !$0.tense.isEmpty && !$0.aspect.isEmpty && !$0.voice.isEmpty && !$0.mood.isEmpty && !$0.why.isEmpty && !$0.svo.agent.isEmpty && !$0.svo.action.isEmpty
        },
        "\(label): tense tab should have complete clause explanations"
    )

    let orderIDs = Set(fixture.wordOrder.en.map(\.id))
    try check(fixture.wordOrder.en.count >= 5, "\(label): order tab should split the sentence into comparable segments")
    try check(Set(fixture.wordOrder.zhOrder) == orderIDs, "\(label): order tab zhOrder should be a permutation of English segment IDs")
    try check(fixture.wordOrder.zhOrder.count == fixture.wordOrder.zhText.count, "\(label): order tab should align zhOrder and zhText")
    try check(fixture.wordOrder.en.contains { $0.moved }, "\(label): order tab should mark moved modifier segments")
    try check(!fixture.wordOrder.note.isEmpty, "\(label): order tab should explain the reordering")

    try check(!fixture.pattern.en.isEmpty && !fixture.pattern.zh.isEmpty, "\(label): pattern section should be reusable")
    try check(fixture.collocations.count >= 3, "\(label): knowledge section should include collocations")
    try check(fixture.phrases.count >= 3, "\(label): knowledge section should include phrases")
    try check(fixture.grammarPoints.count >= 3, "\(label): knowledge section should include grammar points")
    try check(fixture.defaultCollectionItem.title == fixture.pattern.en, "\(label): default collection should match reusable pattern")
}

func flattenTree(_ node: GrammarTreeNode) -> [GrammarTreeNode] {
    [node] + node.children.flatMap(flattenTree)
}

func checkGrammarAIResponseTolerance() throws {
    let json = """
    ```json
    {
      "title": "语法解析",
      "sourceSentence": "The findings call into question assumptions.",
      "chineseMeaning": "这些发现让人们质疑某些假设。",
      "chunks": [
        { "id": "s", "role": "subject", "text": "The findings" },
        { "id": "v", "role": "predicate", "text": "call into question", "label": "谓语" },
        { "id": "o", "role": "object", "text": "assumptions", "note": "宾语" }
      ],
      "tree": {
        "label": "主句",
        "role": "predicate",
        "text": "The findings call into question assumptions.",
        "children": [
          { "label": "主语", "role": "subject", "text": "The findings" },
          { "label": "谓语", "role": "predicate", "text": "call into question" }
        ]
      },
      "trunk": {
        "core": [
          { "w": "The findings", "role": "subject" },
          { "w": "call into question", "role": "predicate" },
          { "w": "assumptions", "role": "object" }
        ],
        "dropped": [],
        "coreZh": "这些发现质疑假设。"
      },
      "wordOrder": {
        "en": [
          { "id": 1, "text": "The findings", "role": "subject" },
          { "id": 2, "text": "call into question", "role": "predicate" },
          { "id": 3, "text": "assumptions", "role": "object" }
        ],
        "zhOrder": [1, 3, 2],
        "zhText": ["这些发现", "假设", "受到质疑"],
        "note": "中文通常把宾语含义提前。"
      },
      "pattern": {
        "en": "sth. calls into question sth.",
        "zh": "某事使某事受到质疑"
      }
    }
    ```
    """

    let extracted = try StructuredJSONExtractor.extractObject(from: "Here is the JSON:\n\(json)")
    let decoded = try JSONDecoder().decode(GrammarResult.self, from: Data(extracted.utf8))

    try check(decoded.analysisScopeNote == "", "grammar decode should default missing scope note")
    try check(decoded.chunks.first?.label == "主语", "grammar chunk should default label from role")
    try check(decoded.chunks.first?.tokens == [], "grammar chunk should default missing tokens")
    try check(decoded.tree.children.first?.children == [], "grammar tree leaf should default missing children")
    try check(decoded.wordOrder.en.first?.moved == false, "grammar order segment should default missing moved flag")
    try check(decoded.defaultCollectionItem.title == "sth. calls into question sth.", "grammar decode should default collection item from pattern")
}

func checkPhraseStore() throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "LingoPeekChecks-\(UUID().uuidString)", directoryHint: .isDirectory)
    let fileURL = directory.appending(path: "phrases.json")
    let store = PhraseStore(fileURL: fileURL)
    let phrases = [
        SavedPhrase(title: "selection-first", note: "以选区为入口。"),
        SavedPhrase(title: "learning object", note: "可拆解、可复用。")
    ]

    try store.save(phrases)
    let loaded = try store.load()
    try check(loaded.map(\.title) == phrases.map(\.title), "phrase titles should persist")
    try check(loaded.map(\.note) == phrases.map(\.note), "phrase notes should persist")
}

do {
    try checkLocalLanguageEngine()
    try checkLanguageActionKeyboardShortcuts()
    try checkDeepSeekRequestFactory()
    try checkOpenAICompatibleRequestFactory()
    try checkSetupGate()
    try checkAIProviderConfiguration()
    try checkStructuredAIResultParsing()
    try checkGrammarResultFixture()
    try checkGrammarUITestFixtures()
    try checkGrammarAIResponseTolerance()
    try checkPhraseStore()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
