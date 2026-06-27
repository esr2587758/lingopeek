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

    let connectivityRequest = try OpenAICompatibleRequestFactory.connectivityTestRequest(configuration: configuration)
    try check(connectivityRequest.url?.absoluteString == "https://api.deepseek.com/chat/completions", "connectivity test should use chat completions endpoint")
    try check(connectivityRequest.timeoutInterval == 30, "connectivity test should fail quickly")

    guard let connectivityBody = connectivityRequest.httpBody else {
        throw CheckFailure.failed("connectivity test should have an HTTP body")
    }
    let connectivityDecoded = try JSONDecoder().decode(OpenAIChatRequest.self, from: connectivityBody)
    try check(connectivityDecoded.model == "deepseek-chat", "connectivity test should keep configured model")
    try check(connectivityDecoded.messages.map(\.role) == ["system", "user"], "connectivity test should include system and user messages")
    try check(connectivityDecoded.messages.last?.content == "ping", "connectivity test should use a tiny ping prompt")
    try check(connectivityDecoded.responseFormat == nil, "connectivity test should not require JSON mode")
    try check(connectivityDecoded.maxTokens == 8, "connectivity test should use a small token budget")
    try check(!connectivityDecoded.stream, "connectivity test should be non-streaming")
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

func checkLingobarSettingsNavigationModel() throws {
    let sections = LingobarSettingsSectionDescriptor.all

    try check(
        sections.map(\.id) == [.general, .ai, .permissions, .trigger, .actions, .collection, .about],
        "settings sections should match the restored Lingobar settings order"
    )
    try check(
        sections.map(\.title) == ["通用", "AI 服务", "权限", "划词与唤起", "语言动作", "收藏", "关于"],
        "settings sections should use restored Lingobar labels"
    )
    try check(
        sections.filter(\.requiresSetupGate).map(\.id) == [.ai, .permissions],
        "AI 服务 and 权限 should be marked as setup-gated sections"
    )

    let blockedGate = LingobarSettingsSetupGate(
        status: SetupGateStatus(aiAccessConfigured: false, accessibilityPermissionGranted: true)
    )
    try check(!blockedGate.isReady, "settings setup gate should block when any required setup is missing")
    try check(blockedGate.footerTitle == "需完成必填项", "blocked settings gate should show required setup copy")
    try check(
        blockedGate.sectionIDsNeedingAttention == [.ai],
        "blocked settings gate should mark only the missing AI section"
    )

    let missingPermissionGate = LingobarSettingsSetupGate(
        status: SetupGateStatus(aiAccessConfigured: true, accessibilityPermissionGranted: false)
    )
    try check(
        missingPermissionGate.sectionIDsNeedingAttention == [.permissions],
        "blocked settings gate should mark only the missing permission section"
    )

    let readyGate = LingobarSettingsSetupGate(
        status: SetupGateStatus(aiAccessConfigured: true, accessibilityPermissionGranted: true)
    )
    try check(readyGate.isReady, "settings setup gate should be ready after AI and Accessibility are configured")
    try check(readyGate.footerTitle.isEmpty, "ready settings gate should not expose reminder copy")
    try check(readyGate.sectionIDsNeedingAttention.isEmpty, "ready settings gate should not mark setup sections")
}

func checkLingobarSettingsSnapshotBehavior() throws {
    try check(
        LingobarAIProvider.allCases.map(\.title) == ["Claude (Anthropic)", "OpenAI", "自定义 / 兼容 OpenAI"],
        "AI provider picker should expose the restored provider choices"
    )

    var settings = LingobarSettingsSnapshot.defaultValue
    try check(settings.launchAtLogin, "settings should default to launch at login enabled")
    try check(settings.showMenuBarIcon, "settings should default to showing the menu bar icon")
    try check(settings.appearanceScheme == .glass, "settings should default to Tahoe glass appearance")
    try check(
        LingobarAppearanceScheme.allCases.map(\.title) == ["Tahoe 玻璃", "克制工具", "温暖阅读", "品牌珊瑚"],
        "appearance picker should expose the restored scheme cards"
    )
    try check(settings.aiProvider == .openAICompatible, "settings should keep the MVP's OpenAI-compatible provider as the default")
    try check(settings.model == "deepseek-chat", "settings should keep DeepSeek-compatible default model")
    try check(settings.baseURLString == "https://api.deepseek.com", "settings should keep DeepSeek-compatible default base URL")
    try check(!settings.setupGateStatus.aiAccessConfigured, "empty API token should leave AI setup incomplete")

    settings.apiToken = " token "
    settings.accessibilityPermissionGranted = true
    try check(settings.setupGateStatus.requiredAction == .useLingobar, "API token and Accessibility should complete setup")

    settings.selectAIProvider(.openAI)
    try check(settings.model == "gpt-4o", "selecting OpenAI should pick the first OpenAI model")
    try check(settings.baseURLString == "https://api.openai.com/v1", "selecting OpenAI should update the compatible base URL")
    settings.selectAIProvider(.claudeAnthropic)
    try check(settings.model == "claude-opus-4-8", "selecting Claude should pick the restored first Claude model")

    try check(
        settings.actionOrder == [.grammar, .translate, .rewrite, .examples, .collect, .pronounce],
        "settings should default language actions to the restored settings prototype order"
    )
    settings.moveAction(.rewrite, before: .grammar)
    try check(
        settings.actionOrder.prefix(3) == [.rewrite, .grammar, .translate],
        "settings should move a language action before another action"
    )

    try check(settings.defaultEnglishAction == .translate, "English selections should default to 翻译")
    try check(settings.defaultChineseMixedAction == .rewrite, "Chinese and mixed selections should default to 改写")
    try check(settings.selectDefaultEnglishAction(.examples), "examples should be selectable as the English default action")
    try check(settings.defaultEnglishAction == .examples, "English default action should update after selection")
    try check(!settings.selectDefaultChineseMixedAction(.grammar), "grammar should not be selectable as the Chinese or mixed default action")
    try check(settings.defaultChineseMixedAction == .rewrite, "invalid Chinese or mixed default action should be ignored")

    try check(settings.collectionTarget == .followCurrentPanel, "collection should default to following the current panel")
    try check(
        LingobarCollectionTarget.allCases.map(\.title) == ["跟随当前面板", "总是收原文"],
        "collection target picker should expose restored copy"
    )
    settings.collectionTarget = .originalSelection
    try check(settings.collectionTarget.description.contains("原始文本"), "selection collection target should describe collecting original text")
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

func checkLanguageActionCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let actions: [LanguageAction] = [.translate, .grammar, .rewrite, .examples, .pronounce]

    for action in actions {
        let data = try encoder.encode(action)
        let encoded = String(decoding: data, as: UTF8.self)
        try check(encoded == "\"\(action.rawValue)\"", "\(action.rawValue) should encode as its raw value")
        let decoded = try decoder.decode(LanguageAction.self, from: data)
        try check(decoded == action, "\(action.rawValue) should decode from its raw value")
    }
}

func checkLingobarHistoryStore() throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "LingoPeekHistoryChecks-\(UUID().uuidString)", directoryHint: .isDirectory)
    let fileURL = directory.appending(path: "history.json")
    let store = LingobarHistoryStore(fileURL: fileURL, limit: 2)

    let missingRecords = try store.load()
    try check(missingRecords.isEmpty, "missing history.json should load empty")

    let firstDate = Date(timeIntervalSince1970: 1_710_000_001)
    let secondDate = Date(timeIntervalSince1970: 1_710_000_002)
    let thirdDate = Date(timeIntervalSince1970: 1_710_000_003)
    let first = try makeHistoryRecord(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        action: .translate,
        sourceText: "first source",
        sourceAppName: "Safari",
        visibleText: "first visible",
        note: "first note",
        itemType: "短语",
        createdAt: firstDate
    )
    let second = try makeHistoryRecord(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        action: .grammar,
        sourceText: "second source",
        sourceAppName: "Notes",
        visibleText: "second visible",
        note: "second note",
        itemType: "句型",
        createdAt: secondDate
    )
    let third = try makeHistoryRecord(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        action: .rewrite,
        sourceText: "third source",
        sourceAppName: "Pages",
        visibleText: "third visible",
        note: "third note",
        itemType: "英文",
        createdAt: thirdDate
    )

    _ = try store.append(first)
    _ = try store.append(second)
    let capped = try store.append(third)
    try check(capped.map(\.id) == [third.id, second.id], "append should keep the two newest records")

    let reloaded = try store.load()
    try check(reloaded == capped, "reload should preserve capped history order and fields")
    try check(reloaded.map(\.createdAt) == [thirdDate, secondDate], "reload should preserve createdAt dates")
    try check(reloaded.map(\.sourceAppName) == ["Pages", "Notes"], "reload should preserve source app labels")

    let afterDelete = try store.delete(id: second.id)
    try check(afterDelete.map(\.id) == [third.id], "delete should remove the matching history UUID")

    let afterMissingDelete = try store.delete(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!)
    try check(afterMissingDelete.map(\.id) == [third.id], "deleting a missing history UUID should be a no-op")

    try store.save([first, second, third])
    let saveCapped = try store.load()
    try check(saveCapped.map(\.id) == [first.id, second.id], "save should enforce the configured history cap")

    try store.clear()
    let clearedRecords = try store.load()
    try check(clearedRecords.isEmpty, "clear should persist an empty history list")

    let corruptFileURL = directory.appending(path: "corrupt-history.json")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("{".utf8).write(to: corruptFileURL, options: [.atomic])
    let corruptStore = LingobarHistoryStore(fileURL: corruptFileURL, limit: 2)
    do {
        _ = try corruptStore.load()
        throw CheckFailure.failed("corrupt history JSON should throw instead of clearing")
    } catch is DecodingError {
        // Expected.
    }
}

func checkLingobarHistoryRecordBuilderPrivacy() throws {
    let createdAt = Date(timeIntervalSince1970: 1_710_000_100)
    let reusableResult = LingobarResult(
        title: "翻译",
        shortcut: "⌘1",
        summary: "Summary text",
        rows: [],
        sideTitle: "后续动作",
        chips: [],
        defaultCollectionItem: DefaultCollectionItem(
            title: " reusable phrase ",
            note: " collection note ",
            type: "短语"
        )
    )

    for action in [LanguageAction.translate, .grammar, .rewrite, .examples, .pronounce] {
        let record = LingobarHistoryRecord.make(
            action: action,
            sourceText: "  source text  ",
            sourceAppName: "  Safari  ",
            result: reusableResult,
            createdAt: createdAt,
            id: UUID()
        )
        try check(record != nil, "\(action.rawValue) should produce a history record")
        try check(record?.action == action, "\(action.rawValue) should be preserved on the history record")
    }

    let record = try requireHistoryRecord(
        LingobarHistoryRecord.make(
            action: .translate,
            sourceText: "  source text  ",
            sourceAppName: "  Safari  ",
            result: reusableResult,
            createdAt: createdAt,
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        ),
        "translate should create a history record"
    )
    try check(record.sourceText == "source text", "history builder should trim source text")
    try check(record.sourceAppName == "Safari", "history builder should trim source app label")
    try check(record.visibleText == "reusable phrase", "history builder should use DefaultCollectionItem title first")
    try check(record.copyText == "reusable phrase", "history builder should use DefaultCollectionItem title for copy text")
    try check(record.note == "collection note", "history builder should use DefaultCollectionItem note")
    try check(record.itemType == "短语", "history builder should use DefaultCollectionItem type")

    let fallbackResult = LingobarResult(
        title: "发音",
        shortcut: "⌘P",
        summary: " pronounced summary ",
        rows: [],
        sideTitle: "后续动作",
        chips: [],
        defaultCollectionTitle: " fallback title "
    )
    let fallback = try requireHistoryRecord(
        LingobarHistoryRecord.make(
            action: .pronounce,
            sourceText: "hello",
            sourceAppName: "   ",
            result: fallbackResult,
            createdAt: createdAt,
            id: UUID()
        ),
        "pronounce should create a fallback history record"
    )
    try check(fallback.sourceAppName == "Lingobar", "empty source app label should default to Lingobar")
    try check(fallback.visibleText == "fallback title", "history builder should fall back to defaultCollectionTitle")
    try check(fallback.copyText == "fallback title", "history builder should fall back to defaultCollectionTitle for copy text")
    try check(fallback.note == "pronounced summary", "history builder should fall back to result summary for note")
    try check(fallback.itemType == "文本", "history builder should fall back to text item type")

    let longText = String(repeating: "A", count: LingobarHistoryLimits.copyTextLength + 20)
    let longRecord = try requireHistoryRecord(
        LingobarHistoryRecord.make(
            action: .examples,
            sourceText: " \(longText) ",
            sourceAppName: "Preview",
            result: LingobarResult(
                title: "例句",
                shortcut: "⌘4",
                summary: longText,
                rows: [],
                sideTitle: "后续动作",
                chips: [],
                defaultCollectionItem: DefaultCollectionItem(
                    title: longText,
                    note: longText,
                    type: "例句"
                )
            ),
            createdAt: createdAt,
            id: UUID()
        ),
        "long examples record should be created"
    )
    try check(longRecord.visibleText.count == LingobarHistoryLimits.visibleTextLength, "visible text should be bounded")
    try check(longRecord.note.count == LingobarHistoryLimits.noteLength, "note should be bounded")
    try check(longRecord.copyText.count == LingobarHistoryLimits.copyTextLength, "copy text should be bounded")
    try check(longRecord.sourceText.count == LingobarHistoryLimits.sourceTextLength, "source text should be bounded")

    try check(
        LingobarHistoryRecord.make(action: .copy, sourceText: "source", sourceAppName: "Safari", result: reusableResult, createdAt: createdAt, id: UUID()) == nil,
        "copy action should not enter history"
    )
    try check(
        LingobarHistoryRecord.make(action: .collect, sourceText: "source", sourceAppName: "Safari", result: reusableResult, createdAt: createdAt, id: UUID()) == nil,
        "collect action should not enter history"
    )

    let encoded = String(decoding: try JSONEncoder().encode(record), as: UTF8.self)
    for forbidden in ["sentinel-token", "https://sentinel.invalid", "sentinel-model", "sentinel-provider"] {
        try check(!encoded.contains(forbidden), "history record should not encode unpassed provider sentinel \(forbidden)")
    }
}

func checkLingobarHubLibraryItems() throws {
    let phraseID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    let phraseDate = Date(timeIntervalSince1970: 1_710_000_200)
    let phrase = SavedPhrase(
        id: phraseID,
        title: "selection-first",
        note: "以选区为入口。",
        createdAt: phraseDate
    )
    let collectionItems = LingobarHubLibrary.collectionItems(from: [phrase])

    try check(collectionItems.count == 1, "one saved phrase should adapt into one Hub collection item")
    let collectionItem = collectionItems[0]
    try check(collectionItem.id == phraseID, "collection item should preserve SavedPhrase id")
    try check(collectionItem.createdAt == phraseDate, "collection item should preserve SavedPhrase date")
    try check(collectionItem.title == phrase.title, "collection item should preserve SavedPhrase title")
    try check(collectionItem.note == phrase.note, "collection item should preserve SavedPhrase note")
    try check(collectionItem.copyText == phrase.title, "collection item copy text should equal title")
    try check(collectionItem.kind == .collection, "collection item kind should be collection")
    try check(collectionItem.source == "Lingobar", "collection item source should default to Lingobar")
    try check(collectionItem.itemType == "文本", "collection item type should default to text")

    let historyDate = Date(timeIntervalSince1970: 1_710_000_300)
    let history = try makeHistoryRecord(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        action: .examples,
        sourceText: "call into question",
        sourceAppName: "Safari",
        visibleText: "The report calls the timeline into question.",
        note: "可迁移例句",
        itemType: "例句",
        createdAt: historyDate
    )
    let historyItems = LingobarHubLibrary.historyItems(from: [history])

    try check(historyItems.count == 1, "one history record should adapt into one Hub history item")
    let historyItem = historyItems[0]
    try check(historyItem.id == history.id, "history item should preserve record id")
    try check(historyItem.kind == .history, "history item kind should be history")
    try check(historyItem.action == .examples, "history item should preserve action")
    try check(historyItem.itemType == "例句", "history item should preserve item type")
    try check(historyItem.source == "Safari", "history item should preserve source app")
    try check(historyItem.createdAt == historyDate, "history item should preserve created date")
    try check(historyItem.sourceText == "call into question", "history item should preserve source text")
    try check(historyItem.copyText == "The report calls the timeline into question.", "history item should preserve copy text")
}

func makeHistoryRecord(
    id: UUID,
    action: LanguageAction,
    sourceText: String,
    sourceAppName: String,
    visibleText: String,
    note: String,
    itemType: String,
    createdAt: Date
) throws -> LingobarHistoryRecord {
    try requireHistoryRecord(
        LingobarHistoryRecord.make(
            action: action,
            sourceText: sourceText,
            sourceAppName: sourceAppName,
            result: LingobarResult(
                title: action.title,
                shortcut: action.shortcut,
                summary: "\(visibleText) summary",
                rows: [],
                sideTitle: "后续动作",
                chips: [],
                defaultCollectionItem: DefaultCollectionItem(
                    title: visibleText,
                    note: note,
                    type: itemType
                )
            ),
            createdAt: createdAt,
            id: id
        ),
        "\(action.rawValue) fixture should produce a history record"
    )
}

func requireHistoryRecord(_ record: LingobarHistoryRecord?, _ message: String) throws -> LingobarHistoryRecord {
    guard let record else {
        throw CheckFailure.failed(message)
    }
    return record
}

func checkLingobarViewModelHistoryRecordingSourceGate() throws {
    let sourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift")
    let source = try String(contentsOf: sourceURL, encoding: .utf8)

    try check(source.contains("private let historyStore: LingobarHistoryStore"), "view model should own an injected history store")
    try check(
        source.contains("init(store: PhraseStore = .defaultStore(), historyStore: LingobarHistoryStore = .defaultStore())"),
        "view model initializer should preserve PhraseStore default and add a default history store"
    )
    try check(source.contains("self.historyStore = historyStore"), "view model initializer should assign the injected history store")
    try check(
        source.contains("let historySourceAppName = mode == .input ? \"输入模式\" : selectionSource"),
        "input-mode history should use the input source label"
    )

    let runAI = try sourceRegion(source, from: "private func runAIIfAvailable", to: "private func recordCompletedHistory")
    let successGuard = try requiredRange(
        in: runAI,
        needle: "guard self.activeAIRequestID == requestID else",
        message: "runAIIfAvailable should keep the successful-decode request guard"
    )
    let recordCall = try requiredRange(
        in: runAI,
        needle: "self.recordCompletedHistory(",
        message: "runAIIfAvailable should record completed history on the success path"
    )
    try check(recordCall.lowerBound > successGuard.lowerBound, "history recording should occur after the successful-decode request guard")
    try check(
        String(runAI[..<successGuard.lowerBound]).doesNotMentionHistoryRecording,
        "history recording should not appear before the successful-decode request guard"
    )
    try check(
        runAI.contains("sourceText: historySourceText") && runAI.contains("sourceAppName: historySourceAppName"),
        "success-path recording should use captured source text and source label"
    )
    try check(
        countOccurrences(of: "self.recordCompletedHistory(", in: runAI) == 1,
        "runAIIfAvailable should call the history recording helper exactly once"
    )

    let catchRegion = String(runAI[try requiredRange(in: runAI, needle: "} catch is DecodingError", message: "runAIIfAvailable should contain the decoding catch branch").lowerBound...])
    try check(catchRegion.doesNotMentionHistoryRecording, "catch/error paths should not record history")

    let helper = try sourceRegion(source, from: "private func recordCompletedHistory", to: "private func systemPrompt")
    try check(helper.contains("LingobarHistoryRecord.make"), "recording helper should build a compact history record")
    try check(helper.contains("_ = try? historyStore.append(record)"), "recording helper should append through the injected history store non-fatally")
    try check(
        helper.doesNotContainAny([
            "AppSettings",
            "AIProviderConfiguration",
            "OpenAICompatibleClient",
            "systemPrompt",
            "completion",
            "json",
            "userFacingAIErrorMessage"
        ]),
        "recording helper should not accept provider config, prompts, raw completion text, JSON, or errors"
    )
    try check(
        countOccurrences(of: "historyStore.append", in: source) == 1,
        "history store append should be isolated to the recording helper"
    )

    let forbiddenRegions = [
        ("grammar fixture", try sourceRegion(source, from: "func presentGrammarFixture", to: "func presentSetupGate")),
        ("setup gate", try sourceRegion(source, from: "func presentSetupGate", to: "func perform")),
        ("copy/collect actions", try sourceRegion(source, from: "func perform", to: "func submitInput")),
        ("result copy", try sourceRegion(source, from: "func copyResult", to: "func copyInlineSelection")),
        ("inline collection", try sourceRegion(source, from: "func collectInlineSelection", to: "func insertResult")),
        ("error result", try sourceRegion(source, from: "private func errorResult", to: "private func userFacingAIErrorMessage"))
    ]

    for (name, region) in forbiddenRegions {
        try check(region.doesNotMentionHistoryRecording, "\(name) region should not record history")
    }
}

func sourceRegion(_ source: String, from start: String, to end: String) throws -> String {
    let startRange = try requiredRange(in: source, needle: start, message: "source should contain \(start)")
    guard let endRange = source[startRange.upperBound...].range(of: end) else {
        throw CheckFailure.failed("source should contain \(end) after \(start)")
    }
    return String(source[startRange.lowerBound..<endRange.lowerBound])
}

func requiredRange(in source: String, needle: String, message: String) throws -> Range<String.Index> {
    guard let range = source.range(of: needle) else {
        throw CheckFailure.failed(message)
    }
    return range
}

func countOccurrences(of needle: String, in source: String) -> Int {
    var count = 0
    var searchStart = source.startIndex
    while let range = source[searchStart...].range(of: needle) {
        count += 1
        searchStart = range.upperBound
    }
    return count
}

private extension String {
    var doesNotMentionHistoryRecording: Bool {
        doesNotContainAny(["recordCompletedHistory(", "historyStore.append"])
    }

    func doesNotContainAny(_ needles: [String]) -> Bool {
        needles.allSatisfy { !contains($0) }
    }
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

func checkLingobarHubShellSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let windowSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarHubWindowController.swift"),
        encoding: .utf8
    )
    let viewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarHubView.swift"),
        encoding: .utf8
    )
    let controllerSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarController.swift"),
        encoding: .utf8
    )
    let appDelegateSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/AppDelegate.swift"),
        encoding: .utf8
    )

    try check(windowSource.contains("LingobarHubWindowController"), "native Hub should have a window controller")
    try check(windowSource.contains("static let hubSize = NSSize(width: 920, height: 624)"), "Hub window should match the reference 920x624 frame")
    try check(windowSource.contains("window.setContentSize(LingobarHubWindow.hubSize)"), "Hub should enforce its reference content size whenever shown")
    try check(windowSource.contains("static let sidebarWidth: CGFloat = 188"), "Hub shell should preserve the 188px sidebar")
    try check(windowSource.contains("window.isMovableByWindowBackground = true"), "Hub window should be draggable by background")
    try check(viewSource.contains("private let detailWidth: CGFloat = 320"), "Hub shell should preserve the 320px detail column")
    try check(viewSource.contains("case collection") && viewSource.contains("case history") && viewSource.contains("case settings"), "Hub should model the three native sections")
    try check(viewSource.contains("\"收藏\"") && viewSource.contains("\"历史\"") && viewSource.contains("\"设置\""), "Hub navigation should use the requested Chinese labels")
    try check(viewSource.contains("\"已就绪\"") && viewSource.contains("\"需完成必填项\""), "Hub footer should reflect setup readiness")
    try check(viewSource.contains("PhraseStore.defaultStore()"), "Hub collection should use the real phrase store")
    try check(viewSource.contains("LingobarHistoryStore.defaultStore()"), "Hub history should use the real history store")
    try check(viewSource.contains("LingobarHubLibrary.collectionItems"), "Hub should map saved phrases through the shared library adapter")
    try check(viewSource.contains("LingobarHubLibrary.historyItems"), "Hub should map history records through the shared library adapter")
    try check(controllerSource.contains("hubWindowController.show(section: .settings)"), "settings entry points should open the Hub settings section")
    try check(controllerSource.contains("hubWindowController.show(section: .collection)"), "menu should expose the Hub collection entry")
    try check(controllerSource.contains("presentFromHub(_ item: LingobarHubLibraryItem)"), "Hub detail items should be able to relaunch Lingobar")
    try check(!controllerSource.contains("settingsWindowController.show()"), "old settings window should not remain the active settings route")
    try check(appDelegateSource.contains("LINGOPEEK_OPEN_HUB"), "app launch should support deterministic Hub UI smoke tests")
    try check(appDelegateSource.contains("LINGOPEEK_OPEN_HUB_SECTION"), "Hub launch should support deterministic section routing")
}

do {
    try checkLocalLanguageEngine()
    try checkLanguageActionKeyboardShortcuts()
    try checkDeepSeekRequestFactory()
    try checkOpenAICompatibleRequestFactory()
    try checkSetupGate()
    try checkLingobarSettingsNavigationModel()
    try checkLingobarSettingsSnapshotBehavior()
    try checkAIProviderConfiguration()
    try checkStructuredAIResultParsing()
    try checkGrammarResultFixture()
    try checkGrammarUITestFixtures()
    try checkGrammarAIResponseTolerance()
    try checkLanguageActionCodable()
    try checkLingobarHistoryStore()
    try checkLingobarHistoryRecordBuilderPrivacy()
    try checkLingobarHubLibraryItems()
    try checkLingobarViewModelHistoryRecordingSourceGate()
    try checkPhraseStore()
    try checkLingobarHubShellSourceGate()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
