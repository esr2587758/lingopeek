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
        LanguageAction.selectionActions.map(\.title) == ["翻译", "语法", "改写", "例句", "保存", "发音"],
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
    try check(engine.result(for: .collect, text: "call into question").title == "保存", "save title should match")

    try check(engine.result(for: .grammar, text: "The findings call into question old assumptions.").moreActionTitle == "继续拆解", "grammar more action should be contextual")
    try check(engine.result(for: .rewrite, text: "我觉得这个方案风险有点高").moreActionTitle == "更多版本", "rewrite more action should be contextual")
    try check(engine.result(for: .examples, text: "call into question").moreActionTitle == "更多例句", "examples more action should be contextual")
    try check(engine.result(for: .pronounce, text: "consolidate").moreActionTitle == "慢速播放", "pronunciation more action should be contextual")
    for action in [LanguageAction.translate, .grammar, .rewrite, .examples, .pronounce] {
        let result = engine.result(for: action, text: "The findings call into question old assumptions.")
        try check(!result.learningInsights.collocations.isEmpty, "\(action.title) should include fixed collocations")
        try check(!result.learningInsights.phrases.isEmpty, "\(action.title) should include common phrases")
        try check(!result.learningInsights.grammarPoints.isEmpty, "\(action.title) should include grammar points")
    }
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
    let customOrder: [LanguageAction] = [.rewrite, .translate, .grammar, .examples, .collect, .pronounce]

    try check(
        LanguageAction.shortcut(for: .rewrite, in: customOrder) == "⌘1",
        "first action slot should display ⌘1"
    )
    try check(
        LanguageAction.shortcut(for: .translate, in: customOrder) == "⌘2",
        "second action slot should display ⌘2"
    )
    try check(
        LanguageAction.shortcut(for: .collect, in: customOrder) == "⌘5",
        "fifth action slot should display ⌘5"
    )
    try check(
        LanguageAction.shortcut(for: .pronounce, in: customOrder) == "⌘P",
        "sixth action slot should display ⌘P"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(
            keyEquivalent: "1",
            command: true,
            actionOrder: customOrder
        ) == .rewrite,
        "⌘1 should trigger the first ordered action"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(
            keyEquivalent: "2",
            command: true,
            actionOrder: customOrder
        ) == .translate,
        "⌘2 should trigger the second ordered action"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(
            keyEquivalent: "P",
            command: true,
            actionOrder: [.pronounce, .translate, .grammar, .rewrite, .examples, .collect]
        ) == .collect,
        "⌘P should trigger the sixth ordered action"
    )
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
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "5", command: true) == .collect,
        "⌘5 should trigger collect"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "P", command: true) == .pronounce,
        "⌘P should trigger pronounce"
    )
    try check(
        LanguageAction.matchingKeyboardShortcut(keyEquivalent: "S", command: true) == nil,
        "⌘S should not be a fixed collect shortcut"
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

func checkLingobarActionDescriptorCatalog() throws {
    let customID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let createdAt = Date(timeIntervalSince1970: 1_710_000_500)
    let custom = CustomPromptAction(
        id: customID,
        title: "润色邮件",
        promptTemplate: "Polish this email and preserve meaning:\n{text}",
        createdAt: createdAt
    )
    try check(
        custom.actionID == "custom:\(customID.uuidString)",
        "custom prompt action IDs should be stable custom-prefixed UUIDs"
    )
    try check(
        custom.userPrompt(for: "hello").contains("Polish this email") &&
            custom.userPrompt(for: "hello").contains("hello") &&
            !custom.userPrompt(for: "hello").contains("{text}"),
        "custom prompt action should replace the optional {text} placeholder"
    )

    let noPlaceholder = CustomPromptAction(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "提炼观点",
        promptTemplate: "Summarize the user's point in one sentence.",
        createdAt: createdAt
    )
    try check(
        noPlaceholder.userPrompt(for: "source text").contains("Text:\nsource text"),
        "custom prompt action without {text} should append the current text automatically"
    )

    let descriptors = LingobarActionCatalog.descriptors(
        customPromptActions: [custom],
        orderIDs: [custom.actionID, LanguageAction.rewrite.actionID, LanguageAction.translate.actionID]
    )
    try check(Array(descriptors.map(\.id).prefix(3)) == [custom.actionID, "rewrite", "translate"], "descriptor order should respect saved action IDs")
    try check(descriptors.first?.title == "润色邮件", "custom descriptor should expose its saved title")
    try check(descriptors.first?.symbol == "sparkles", "custom descriptor should use the custom action symbol")
    try check(
        LingobarActionCatalog.shortcut(for: descriptors[0], in: descriptors) == "⌘1" &&
            LingobarActionCatalog.shortcut(for: descriptors[1], in: descriptors) == "⌘2",
        "custom and built-in actions should share the ordered shortcut slots"
    )
    try check(
        LingobarActionCatalog.matchingKeyboardShortcut(
            keyEquivalent: "1",
            command: true,
            descriptors: descriptors
        )?.id == custom.actionID,
        "⌘1 should resolve to the first descriptor, including custom prompt actions"
    )
    try check(
        LingobarActionCatalog.nextEligibleDefaultActionID(
            after: custom.actionID,
            orderIDs: [LanguageAction.translate.actionID, custom.actionID, LanguageAction.grammar.actionID],
            customPromptActions: []
        ) == LanguageAction.grammar.actionID,
        "deleting a default custom action should advance to the next ordered result action"
    )
}

func checkCustomPromptActionHistorySnapshot() throws {
    let custom = CustomPromptAction(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "面试回答",
        promptTemplate: "Turn {text} into a concise interview answer.",
        createdAt: Date(timeIntervalSince1970: 1_710_000_501)
    )
    let descriptor = LingobarActionDescriptor(customPromptAction: custom)
    let result = LingobarResult(
        title: custom.title,
        shortcut: "⌘1",
        summary: "A concise answer.",
        rows: [LingobarRow("版本", "A concise answer.")],
        sideTitle: "后续动作",
        chips: [],
        moreActionTitle: "继续处理",
        defaultCollectionItem: DefaultCollectionItem(title: "A concise answer.", note: "面试回答", type: "文本")
    )
    let record = try requireHistoryRecord(
        LingobarHistoryRecord.make(
            action: descriptor,
            sourceText: "raw answer",
            sourceAppName: "Safari",
            result: result,
            createdAt: Date(timeIntervalSince1970: 1_710_000_502),
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        ),
        "custom prompt history record should be created"
    )

    try check(record.action == .rewrite, "custom prompt history should use rewrite as a Codable legacy fallback action")
    try check(record.actionID == custom.actionID, "custom prompt history should preserve the custom action ID")
    try check(record.actionTitle == custom.title, "custom prompt history should preserve the custom action title")
    try check(record.storedSnapshot(for: custom.actionID)?.result == result, "custom prompt history should key snapshots by action ID")

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(LingobarHistoryRecord.self, from: try encoder.encode(record))
    try check(decoded.actionID == custom.actionID, "custom prompt action ID should survive history JSON round-trip")
    try check(decoded.actionTitle == custom.title, "custom prompt action title should survive history JSON round-trip")
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
    try check(decoded.thinking?.type == "disabled", "DeepSeek v4 requests should disable thinking for JSON completions")
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
    try check(decoded.thinking == nil, "OpenAI-compatible request should not add provider-specific thinking options for normal models")
    try check(!decoded.stream, "OpenAI-compatible request should be non-streaming")

    let deepSeekV4Configuration = AIProviderConfiguration(
        apiToken: "test-token",
        baseURLString: "https://api.deepseek.com",
        model: "deepseek-v4-flash"
    )
    let deepSeekV4Request = try OpenAICompatibleRequestFactory.request(
        configuration: deepSeekV4Configuration,
        system: "system prompt",
        user: "hello",
        maxTokens: 1000
    )
    guard let deepSeekV4Body = deepSeekV4Request.httpBody else {
        throw CheckFailure.failed("DeepSeek v4 request should have an HTTP body")
    }
    let deepSeekV4Decoded = try JSONDecoder().decode(OpenAIChatRequest.self, from: deepSeekV4Body)
    try check(deepSeekV4Decoded.maxTokens == 1000, "OpenAI-compatible request should allow per-request token budgets")
    try check(deepSeekV4Decoded.thinking?.type == "disabled", "DeepSeek v4 OpenAI-compatible requests should disable thinking")

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
    try check(connectivityDecoded.thinking == nil, "connectivity test should not include provider-specific thinking options")
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
      },
      "learningInsights": {
        "collocations": [
          {
            "phrase": "call into question",
            "pos": "v. phr.（动词短语）",
            "zh": "对……提出质疑",
            "note": "用于证据挑战旧观点",
            "example": "The findings call into question old assumptions."
          }
        ],
        "phrases": [
          { "en": "long-held assumptions", "zh": "长期假设" }
        ],
        "grammarPoints": [
          { "tag": "搭配", "title": "call into question 后接宾语", "body": "后面接被质疑的对象。" }
        ]
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
    try check(result.learningInsights.collocations.first?.phrase == "call into question", "structured AI result should keep learning collocations")
    try check(result.learningInsights.phrases.first?.en == "long-held assumptions", "structured AI result should keep learning phrases")
    try check(result.learningInsights.grammarPoints.first?.title.contains("call into question") == true, "structured AI result should keep grammar points")

    let sparse = #"{"title":"翻译"}"#.data(using: .utf8)!
    let sparseStructured = try JSONDecoder().decode(StructuredLingobarResult.self, from: sparse)
    try check(sparseStructured.summary == "", "sparse structured AI result should default missing summary")
    try check(sparseStructured.rows == [LingobarRow("结果", "")], "sparse structured AI result should default missing rows")
    try check(sparseStructured.learningInsights.isEmpty, "sparse structured AI result should default missing learning insights")

    let rewrite = """
    {
      "title": "改写",
      "variants": {
        "natural": "Traveling across China, one cigarette at a time.",
        "concise": "Crossing China, cigarette by cigarette."
      },
      "chips": "one cigarette at a time"
    }
    """.data(using: .utf8)!
    let rewriteStructured = try JSONDecoder().decode(StructuredLingobarResult.self, from: rewrite)
    try check(rewriteStructured.summary.contains("cigarette"), "rewrite variants should provide a summary")
    try check(rewriteStructured.rows.count == 2, "rewrite variants object should become rows")
    try check(rewriteStructured.chips == ["one cigarette at a time"], "single chip string should become a chip array")
    try check(!rewriteStructured.defaultCollectionItem.title.isEmpty, "rewrite variants should default a collection item")
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

func checkGrammarAbbreviationGlossary() throws {
    try check(GrammarAbbreviationGlossary.displayText(for: "S") == "S · 句子", "grammar glossary should explain S")
    try check(GrammarAbbreviationGlossary.displayText(for: "AdvP") == "AdvP · 状语短语", "grammar glossary should explain AdvP")
    try check(GrammarAbbreviationGlossary.displayText(for: "ConjP") == "ConjP · 连接短语", "grammar glossary should explain ConjP")
    try check(GrammarAbbreviationGlossary.displayText(for: "adv") == "adv · 副词/状语", "grammar glossary should explain adv")
    try check(GrammarAbbreviationGlossary.displayText(for: "prep") == "prep · 介词", "grammar glossary should explain prep")
    try check(GrammarAbbreviationGlossary.displayText(for: "past") == "past · 过去时", "grammar glossary should explain tense terms")
    try check(GrammarAbbreviationGlossary.displayText(for: "simple") == "simple · 一般体", "grammar glossary should explain aspect terms")
    try check(GrammarAbbreviationGlossary.displayText(for: "active") == "active · 主动", "grammar glossary should explain voice terms")
    try check(GrammarAbbreviationGlossary.displayText(for: "indicative") == "indicative · 陈述语气", "grammar glossary should explain mood terms")
    try check(GrammarAbbreviationGlossary.displayText(for: "non-finite") == "non-finite · 非限定", "grammar glossary should explain non-finite forms")
    try check(
        GrammarAbbreviationGlossary.displayText(for: "v. phr. (passive)") == "v. phr. (passive) · 动词短语（被动）",
        "grammar glossary should explain qualified phrase abbreviations"
    )
    try check(
        GrammarAbbreviationGlossary.displayText(for: "concessive clause") == "concessive clause · 让步从句",
        "grammar glossary should explain common English grammar terms"
    )
    try check(
        GrammarAbbreviationGlossary.displayText(for: "prep（介词）") == "prep（介词）",
        "grammar glossary should not duplicate existing Chinese notes"
    )
}

func checkGrammarChunkNormalization() throws {
    let duplicateSource = "This means you can keep your main application responsive (e.g., a web server or UI) while the agent continues its work, only inspecting the result when you need it."
    let duplicateChunks = [
        GrammarChunk(id: "s", role: .subject, text: "This", label: "主语", note: "代词作主语"),
        GrammarChunk(id: "v", role: .predicate, text: "means", label: "谓语", note: "及物动词"),
        GrammarChunk(
            id: "o",
            role: .object,
            text: "you can keep your main application responsive (e.g., a web server or UI) while the agent continues its work, only inspecting the result when you need it",
            label: "宾语从句",
            note: "整个从句作宾语"
        ),
        GrammarChunk(id: "sub-s", role: .subject, text: "you", label: "从句主语", note: "宾语从句中的主语"),
        GrammarChunk(id: "sub-v", role: .predicate, text: "can keep", label: "从句谓语", note: "情态动词 + 动词原形"),
        GrammarChunk(
            id: "sub-o",
            role: .object,
            text: "your main application responsive (e.g., a web server or UI)",
            label: "从句宾语",
            note: "keep 的宾语和宾补"
        ),
        GrammarChunk(
            id: "adv",
            role: .adv,
            text: "while the agent continues its work, only inspecting the result when you need it",
            label: "状语",
            note: "说明并行动作和检查时机"
        )
    ]

    let normalizedDuplicate = GrammarResult.normalizedChunks(duplicateChunks, in: duplicateSource)
    try check(
        normalizedDuplicate.map(\.text) == [
            "This",
            "means",
            "you",
            "can keep",
            "your main application responsive (e.g., a web server or UI)",
            "while the agent continues its work, only inspecting the result when you need it"
        ],
        "grammar chunk normalization should remove a duplicated parent clause while preserving child chunks"
    )
    try check(
        !normalizedDuplicate.contains { $0.id == "o" },
        "grammar chunk normalization should drop the coarse parent object clause"
    )

    let adverbialSource = "Search and Fetch connects to PatSnap patent and paper search and fetch capabilities, allowing the AI assistant to search for relevant records and retrieve detailed information for selected items."
    let coarseAdverbial = "allowing the AI assistant to search for relevant records and retrieve detailed information for selected items"
    let normalizedAdverbial = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "s", role: .subject, text: "Search and Fetch", label: "主语", note: "专有名词，功能名称"),
            GrammarChunk(id: "v", role: .predicate, text: "connects to", label: "谓语", note: "动词短语，表示连接"),
            GrammarChunk(
                id: "o",
                role: .object,
                text: "PatSnap patent and paper search and fetch capabilities",
                label: "宾语",
                note: "名词短语，表示连接的对象"
            ),
            GrammarChunk(id: "adv", role: .adv, text: coarseAdverbial, label: "状语", note: "现在分词短语作结果状语")
        ],
        in: adverbialSource
    )

    try check(
        !normalizedAdverbial.contains { $0.text == coarseAdverbial },
        "grammar chunk normalization should split oversized present-participle adverbials"
    )
    try check(
        normalizedAdverbial.contains { $0.text == "allowing" && $0.role == .adv },
        "grammar chunk normalization should keep the participle as a small adverbial marker"
    )
    try check(
        normalizedAdverbial.contains { $0.text == "the AI assistant" && $0.role == .object },
        "grammar chunk normalization should expose the internal object of an oversized adverbial"
    )
    try check(
        normalizedAdverbial.contains { $0.text == "to search for relevant records" && $0.role == .predicate },
        "grammar chunk normalization should expose the first infinitive action"
    )
    try check(
        normalizedAdverbial.contains { $0.text == "and retrieve detailed information for selected items" && $0.role == .predicate },
        "grammar chunk normalization should expose the coordinated infinitive action"
    )

    let relativeClauseSource = "The Auckland region of New Zealand is built on a basement of greywacke rocks that form many of the islands in the Hauraki Gulf, the Hunua Ranges, and land south of Port Waikato."
    let normalizedRelativeClause = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "s", role: .subject, text: "The Auckland region of New Zealand", label: "主语", note: "地名区域作主语"),
            GrammarChunk(id: "v", role: .predicate, text: "is built on", label: "谓语", note: "被动谓语"),
            GrammarChunk(id: "o", role: .object, text: "a basement of greywacke rocks", label: "宾语", note: "介词 on 的宾语"),
            GrammarChunk(id: "attr", role: .attr, text: "that form many of the islands in the Hauraki Gulf", label: "定语从句", note: "修饰 rocks"),
            GrammarChunk(id: "tail-1", role: .object, text: "the Hunua Ranges", label: "并列宾语", note: "AI 曾误提升为主句级宾语"),
            GrammarChunk(id: "tail-2", role: .object, text: "and land south of Port Waikato", label: "并列宾语", note: "AI 曾误提升为主句级宾语")
        ],
        in: relativeClauseSource
    )

    try check(
        normalizedRelativeClause.contains { $0.text == "that" && $0.role == .conj },
        "relative-clause normalization should split the relative connector out of the coarse clause"
    )
    try check(
        normalizedRelativeClause.contains { $0.text == "form" && $0.role == .predicate },
        "relative-clause normalization should expose the relative-clause predicate"
    )
    try check(
        normalizedRelativeClause.contains { $0.text == "many of the islands in the Hauraki Gulf" && $0.role == .object && $0.label.contains("定语从句") },
        "relative-clause normalization should keep the first internal object scoped to the relative clause"
    )
    try check(
        normalizedRelativeClause.first { $0.text == "the Hunua Ranges" }?.label.contains("定语从句") == true,
        "relative-clause normalization should label the first tail object as relative-clause internal"
    )
    try check(
        normalizedRelativeClause.first { $0.text == "and land south of Port Waikato" }?.label.contains("定语从句") == true,
        "relative-clause normalization should label the second tail object as relative-clause internal"
    )

    let duplicateRelativePronounSource = "The convergence of fashion and high technology is leading to new kinds of fibres, fabrics and coatings that are imbuing clothing with equally wondrous powers."
    let normalizedDuplicateRelativePronoun = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "s", role: .subject, text: "The convergence of fashion and high technology", label: "主语", note: "抽象名词短语"),
            GrammarChunk(id: "v", role: .predicate, text: "is leading to", label: "谓语", note: "现在进行时谓语"),
            GrammarChunk(id: "o", role: .object, text: "new kinds of fibres, fabrics and coatings", label: "宾语", note: "介词 to 的宾语"),
            GrammarChunk(id: "rel", role: .conj, text: "that", label: "关系代词", note: "引导定语从句"),
            GrammarChunk(id: "rel-s", role: .subject, text: "that", label: "从句主语", note: "that 在定语从句中作主语"),
            GrammarChunk(id: "rel-v", role: .predicate, text: "are imbuing", label: "从句谓语", note: "定语从句谓语"),
            GrammarChunk(id: "rel-o", role: .object, text: "clothing", label: "从句宾语", note: "imbuing 的宾语"),
            GrammarChunk(id: "rel-adv", role: .adv, text: "with equally wondrous powers", label: "方式/内容状语", note: "with 短语说明赋予的内容")
        ],
        in: duplicateRelativePronounSource
    )

    try check(
        normalizedDuplicateRelativePronoun.filter { $0.text == "that" }.count == 1,
        "relative pronoun used as clause subject should render once, not as connector plus duplicate subject"
    )
    try check(
        normalizedDuplicateRelativePronoun.first { $0.text == "that" }?.label.contains("从句主语") == true,
        "merged relative pronoun should preserve its relative-clause subject role in the label"
    )
    try check(
        normalizedDuplicateRelativePronoun.map(\.text).joined(separator: " ").doesNotContainAny(["that that", "which which"]),
        "normalized chunks should not create duplicated relative-pronoun surface text"
    )

    let coordinatedPredicateSource = "Despite an initial positive reception in Europe, the series was panned by critics, viewers, and longtime fans for its animation, writing, and deviations from its predecessor, and has since been widely regarded as one of the worst animated series ever made."
    let normalizedCoordinatedPredicate = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "adv", role: .adv, text: "Despite an initial positive reception in Europe", label: "让步状语", note: "让步介词短语"),
            GrammarChunk(id: "s", role: .subject, text: "the series", label: "主语", note: "共享主语"),
            GrammarChunk(id: "v1", role: .predicate, text: "was panned", label: "谓语", note: "第一个被动谓语"),
            GrammarChunk(id: "by", role: .adv, text: "by critics, viewers, and longtime fans", label: "施事状语", note: "被动结构的 by 短语"),
            GrammarChunk(id: "for", role: .adv, text: "for its animation, writing, and deviations from its predecessor", label: "原因状语", note: "说明批评原因"),
            GrammarChunk(id: "v2", role: .adv, text: "and has since been widely regarded", label: "状语", note: "AI 曾误标为状语"),
            GrammarChunk(id: "comp", role: .object, text: "as one of the worst animated series ever made", label: "补足语", note: "regarded as 的补足成分")
        ],
        in: coordinatedPredicateSource
    )

    try check(
        normalizedCoordinatedPredicate.first { $0.text == "and has since been widely regarded" }?.role == .predicate,
        "coordinated finite verb phrase should normalize from adverbial to predicate"
    )
    try check(
        normalizedCoordinatedPredicate.first { $0.text == "and has since been widely regarded" }?.label.contains("并列谓语") == true,
        "coordinated finite verb phrase should be labeled as a coordinated predicate"
    )

    let copularComplementSource = "The feel good factor that most proponents of Olympic bids extol, and that was no doubt driving the approval rates of Parisians and Londoners for their cities' respective bids, can be an elusive phenomenon, and one that is tied to that nation's standing on the medal tables."
    let normalizedCopularComplement = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "s", role: .subject, text: "The feel good factor", label: "主语", note: "主句主语"),
            GrammarChunk(id: "attr-1", role: .attr, text: "that most proponents of Olympic bids extol", label: "定语从句", note: "修饰 factor"),
            GrammarChunk(id: "attr-2", role: .attr, text: "and that was no doubt driving the approval rates of Parisians and Londoners for their cities' respective bids", label: "并列定语从句", note: "继续修饰 factor"),
            GrammarChunk(id: "v", role: .predicate, text: "can be", label: "谓语", note: "系动词结构"),
            GrammarChunk(id: "c1", role: .object, text: "an elusive phenomenon", label: "宾语", note: "AI 曾误标为宾语"),
            GrammarChunk(id: "c2", role: .object, text: "and one that is tied to that nation's standing on the medal tables", label: "并列宾语", note: "AI 曾误标为第二宾语")
        ],
        in: copularComplementSource
    )

    try check(
        normalizedCopularComplement.first { $0.text == "an elusive phenomenon" }?.role == .appos,
        "copular complement after can be should normalize away from object"
    )
    try check(
        normalizedCopularComplement.first { $0.text == "an elusive phenomenon" }?.label.contains("表语") == true,
        "copular complement should be labeled as predicative complement"
    )
    try check(
        normalizedCopularComplement.first { $0.text == "and one that is tied to that nation's standing on the medal tables" }?.role == .appos,
        "coordinated copular complement should normalize away from object"
    )

    let invertedCopularSource = "Even more confounding than Manet's relaxed attention to detail, however, is the relationship in the painting between the activity in the mirrored reflection and that which we see in the unreflected foreground."
    let normalizedInvertedCopular = GrammarResult.normalizedChunks(
        [
            GrammarChunk(id: "front", role: .adv, text: "Even more confounding than Manet's relaxed attention to detail", label: "状语", note: "AI 曾误标为状语"),
            GrammarChunk(id: "v", role: .predicate, text: "is", label: "谓语", note: "倒装系动词"),
            GrammarChunk(id: "place", role: .adv, text: "in the painting", label: "地点状语", note: "AI 输出中保留的局部短语"),
            GrammarChunk(id: "mirror", role: .adv, text: "in the mirrored reflection", label: "地点状语", note: "AI 输出中保留的局部短语"),
            GrammarChunk(id: "relative", role: .attr, text: "that which we see in the unreflected foreground", label: "定语从句", note: "修饰 activity/that")
        ],
        in: invertedCopularSource
    )

    try check(
        normalizedInvertedCopular.first?.role == .appos,
        "fronted inverted copular complement should normalize away from adverbial"
    )
    try check(
        normalizedInvertedCopular.contains { $0.role == .subject && $0.text.contains("the relationship") && $0.text.contains("the activity") },
        "inverted copular normalization should restore the omitted subject noun phrase"
    )
    try check(
        normalizedInvertedCopular.map(\.text).joined(separator: " ").contains("the relationship"),
        "inverted copular normalized chunks should not drop the relationship token"
    )
    try check(
        normalizedInvertedCopular.map(\.text).joined(separator: " ").contains("the activity"),
        "inverted copular normalized chunks should not drop the activity token"
    )

    let olympicBidSource = "The staggering expenses involved in a successful Olympic bid are often assumed to be easily mitigated by tourist revenues and an increase in local employment, but more often than not host cities are short changed and their taxpayers for generations to come are left settling the debt."
    let olympicBidRecovery = GrammarResult.recoveryChunks(for: olympicBidSource)
    try check(
        olympicBidRecovery.first { $0.text == "The staggering expenses involved in a successful Olympic bid" }?.role == .subject,
        "Olympic bid schema recovery should identify the passive main-clause subject"
    )
    try check(
        olympicBidRecovery.first { $0.text == "are often assumed to be easily mitigated" }?.role == .predicate,
        "Olympic bid schema recovery should identify the passive main-clause predicate"
    )
    try check(
        olympicBidRecovery.first { $0.text == "by tourist revenues and an increase in local employment" }?.role == .adv,
        "Olympic bid schema recovery should keep the by-phrase as an adverbial"
    )
    try check(
        olympicBidRecovery.first { $0.text == "but" }?.role == .conj,
        "Olympic bid schema recovery should keep the contrast connector"
    )
    try check(
        olympicBidRecovery.first { $0.text == "more often than not" }?.role == .adv,
        "Olympic bid schema recovery should identify the contrast-half frequency adverbial"
    )
    try check(
        olympicBidRecovery.first { $0.text == "host cities" }?.role == .subject,
        "Olympic bid schema recovery should identify the first contrast subject"
    )
    try check(
        olympicBidRecovery.first { $0.text == "are short changed" }?.role == .predicate,
        "Olympic bid schema recovery should identify the first contrast passive predicate"
    )
    try check(
        olympicBidRecovery.first { $0.text == "their taxpayers for generations to come" }?.role == .subject,
        "Olympic bid schema recovery should identify the second contrast subject"
    )
    try check(
        olympicBidRecovery.first { $0.text == "are left settling" }?.role == .predicate,
        "Olympic bid schema recovery should identify the second contrast passive predicate"
    )
    try check(
        olympicBidRecovery.first { $0.text == "the debt" }?.role == .object,
        "Olympic bid schema recovery should identify the settling object"
    )

    let sharkSenseSource = "As the shark reaches proximity to its prey, it tunes into electric signals that ensure a precise strike on its target; this sense is so strong that the shark even attacks blind by letting its eyes recede for protection."
    let sharkSenseRecovery = GrammarResult.recoveryChunks(for: sharkSenseSource)
    try check(
        sharkSenseRecovery.first { $0.text == "As the shark reaches proximity to its prey" }?.role == .adv,
        "shark sense schema recovery should identify the as time clause"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "it" }?.role == .subject,
        "shark sense schema recovery should identify the first main-clause subject"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "tunes into" }?.role == .predicate,
        "shark sense schema recovery should identify the first main-clause predicate"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "electric signals" }?.role == .object,
        "shark sense schema recovery should identify the signal object before the relative clause"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "that" }?.role == .conj,
        "shark sense schema recovery should split the relative connector"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "so strong" }?.role == .appos,
        "shark sense schema recovery should identify the so ... that degree complement"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "the shark" }?.role == .subject,
        "shark sense schema recovery should identify the result-clause subject"
    )
    try check(
        sharkSenseRecovery.first { $0.text == "even attacks blind" }?.role == .predicate,
        "shark sense schema recovery should identify the result-clause predicate"
    )

    let olympicConcernSource = "Another major concern is that when civic infrastructure developments are undertaken in preparation for hosting the Olympics, these benefits accrue to a single metropolitan centre with the exception of some outlying areas that may get some revamped sports facilities."
    let olympicConcernRecovery = GrammarResult.recoveryChunks(for: olympicConcernSource)
    try check(
        olympicConcernRecovery.first { $0.text == "Another major concern" }?.role == .subject,
        "concern schema recovery should identify the copular subject"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "is" }?.role == .predicate,
        "concern schema recovery should identify the copular predicate"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "that" }?.role == .conj,
        "concern schema recovery should identify the content-clause connector"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "when" }?.role == .conj,
        "concern schema recovery should identify the embedded when connector"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "civic infrastructure developments" }?.role == .subject,
        "concern schema recovery should identify the embedded when-clause subject"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "are undertaken" }?.role == .predicate,
        "concern schema recovery should identify the embedded when-clause passive predicate"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "in preparation for hosting the Olympics" }?.role == .adv,
        "concern schema recovery should identify the embedded when-clause preparation phrase"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "these benefits" }?.role == .subject,
        "concern schema recovery should identify the content-clause subject"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "accrue to" }?.role == .predicate,
        "concern schema recovery should identify the content-clause predicate"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "with the exception of some outlying areas" }?.role == .adv,
        "concern schema recovery should identify the exception phrase"
    )
    try check(
        olympicConcernRecovery.first { $0.text == "that may get some revamped sports facilities" }?.role == .attr,
        "concern schema recovery should preserve the outlying-areas relative clause"
    )

    let hawkingSource = "World-renowned astrophysicist Stephen Hawking believes that once spaceships can exceed the speed of light, humans could feasibly travel millions of years into the future in order to repopulate earth in the event of a forthcoming apocalypse."
    let hawkingRecovery = GrammarResult.recoveryChunks(for: hawkingSource)
    try check(
        hawkingRecovery.first { $0.text == "World-renowned astrophysicist Stephen Hawking" }?.role == .subject,
        "Hawking schema recovery should identify the reporting subject"
    )
    try check(
        hawkingRecovery.first { $0.text == "believes" }?.role == .predicate,
        "Hawking schema recovery should identify the reporting predicate"
    )
    try check(
        hawkingRecovery.first { $0.text == "that" }?.role == .conj,
        "Hawking schema recovery should identify the object-clause connector"
    )
    try check(
        hawkingRecovery.first { $0.text == "once" }?.role == .conj,
        "Hawking schema recovery should identify the once connector"
    )
    try check(
        hawkingRecovery.first { $0.text == "spaceships" }?.role == .subject,
        "Hawking schema recovery should identify the once-clause subject"
    )
    try check(
        hawkingRecovery.first { $0.text == "can exceed" }?.role == .predicate,
        "Hawking schema recovery should identify the once-clause predicate"
    )
    try check(
        hawkingRecovery.first { $0.text == "the speed of light" }?.role == .object,
        "Hawking schema recovery should identify the once-clause object"
    )
    try check(
        hawkingRecovery.first { $0.text == "humans" }?.role == .subject,
        "Hawking schema recovery should identify the embedded-clause subject"
    )
    try check(
        hawkingRecovery.first { $0.text == "could feasibly travel" }?.role == .predicate,
        "Hawking schema recovery should identify the embedded-clause predicate"
    )
    try check(
        hawkingRecovery.first { $0.text == "in order to repopulate earth" }?.role == .adv,
        "Hawking schema recovery should identify the purpose phrase"
    )
    try check(
        hawkingRecovery.first { $0.text == "in the event of a forthcoming apocalypse" }?.role == .adv,
        "Hawking schema recovery should identify the condition phrase"
    )
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

    try check(LingobarHistoryLimits.defaultRecordLimit == 50, "default history cap should keep the 50 newest expiring records")

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
    try check(reloaded[0].resultSnapshot.defaultCollectionItem?.type == "英文", "history should persist the full result snapshot")
    try check(reloaded[0].snapshot(for: .rewrite)?.defaultCollectionItem?.type == "英文", "history should index the latest snapshot by action")

    let afterDelete = try store.delete(id: second.id)
    try check(afterDelete.map(\.id) == [third.id], "delete should remove the matching history UUID")

    let afterMissingDelete = try store.delete(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!)
    try check(afterMissingDelete.map(\.id) == [third.id], "deleting a missing history UUID should be a no-op")

    try store.save([first, second, third])
    let saveCapped = try store.load()
    try check(saveCapped.map(\.id) == [first.id, second.id], "save should enforce the configured history cap")

    var savedFirst = first
    savedFirst.isSaved = true
    try store.save([third, second, savedFirst])
    let savedBeyondCap = try store.load()
    try check(savedBeyondCap.map(\.id) == [third.id, second.id, first.id], "saved history should not expire when the unsaved cap is reached")
    let unsavedAgain = try store.setSaved(id: first.id, isSaved: false)
    try check(unsavedAgain.map(\.id) == [third.id, second.id], "unmarking saved history should make it expire under the cap")

    try store.clear()
    let clearedRecords = try store.load()
    try check(clearedRecords.isEmpty, "clear should persist an empty history list")

    let sharedTranslate = try makeHistoryRecord(
        id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        action: .translate,
        sourceText: " shared source ",
        sourceAppName: "Safari",
        visibleText: "shared translation",
        note: "translation note",
        itemType: "翻译",
        createdAt: firstDate
    )
    let sharedRewrite = try makeHistoryRecord(
        id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        action: .rewrite,
        sourceText: "shared source",
        sourceAppName: "Safari",
        visibleText: "shared rewrite",
        note: "rewrite note",
        itemType: "改写",
        createdAt: secondDate
    )
    _ = try store.append(sharedTranslate)
    let mergedShared = try store.append(sharedRewrite)
    try check(mergedShared.count == 1, "history should merge repeated LLM actions for the same selected sentence")
    try check(mergedShared[0].sourceText == "shared source", "merged history should keep the selected sentence as the source text")
    try check(mergedShared[0].action == .rewrite, "merged history should expose the latest action")
    try check(mergedShared[0].resultSnapshot == sharedRewrite.resultSnapshot, "merged history should use the latest action as the primary restorable snapshot")
    try check(mergedShared[0].snapshot(for: .translate) == sharedTranslate.resultSnapshot, "merged history should keep the translate snapshot")
    try check(mergedShared[0].snapshot(for: .rewrite) == sharedRewrite.resultSnapshot, "merged history should keep the rewrite snapshot")
    try check(mergedShared[0].resultSnapshots.keys.sorted() == ["rewrite", "translate"], "merged history should encode a full action-keyed snapshot map")

    try store.save([sharedRewrite, sharedTranslate])
    let coalescedLegacyShape = try store.load()
    try check(coalescedLegacyShape.count == 1, "loading existing per-action history should coalesce records for the same selected sentence")
    try check(coalescedLegacyShape[0].resultSnapshot == sharedRewrite.resultSnapshot, "coalesced load should keep the newest stored row as the primary snapshot")
    try check(coalescedLegacyShape[0].snapshot(for: .translate) == sharedTranslate.resultSnapshot, "coalesced load should retain older action snapshots")

    try store.clear()
    _ = try store.saveOrAppend(first)
    _ = try store.saveOrAppend(first)
    let upsertedSavedRecords = try store.load()
    try check(upsertedSavedRecords.count == 1, "saving history should update the same record instead of duplicating it")
    try check(upsertedSavedRecords[0].isSaved, "saving history should mark the record as non-expiring")
    _ = try store.append(first)
    let appendAfterSaveRecords = try store.load()
    try check(appendAfterSaveRecords.count == 1, "late history append should not duplicate a saved record with the same id")
    try check(appendAfterSaveRecords[0].isSaved, "late history append should preserve the saved state")

    let legacyFileURL = directory.appending(path: "legacy-history.json")
    let legacyJSON = """
    [
      {
        "id": "88888888-8888-8888-8888-888888888888",
        "action": "translate",
        "itemType": "短语",
        "visibleText": "legacy phrase",
        "copyText": "legacy phrase",
        "note": "legacy note",
        "sourceText": "legacy source",
        "sourceAppName": "Safari",
        "createdAt": "2024-03-09T16:05:00Z"
      }
    ]
    """
    try Data(legacyJSON.utf8).write(to: legacyFileURL, options: [.atomic])
    let legacyRecords = try LingobarHistoryStore(fileURL: legacyFileURL).load()
    try check(legacyRecords.count == 1, "legacy compact history records should decode")
    try check(legacyRecords[0].itemType == "短语", "legacy history should preserve item type")
    try check(!legacyRecords[0].isSaved, "legacy history should default to expiring")
    try check(legacyRecords[0].resultSnapshot.defaultCollectionItem?.title == "legacy phrase", "legacy history should synthesize a restorable snapshot")
    try check(legacyRecords[0].snapshot(for: .translate)?.defaultCollectionItem?.title == "legacy phrase", "legacy history should synthesize an action-keyed snapshot for old compact records")

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
    try check(record.resultSnapshot == reusableResult, "history builder should preserve the complete Lingobar result snapshot")
    try check(record.snapshot(for: .translate) == reusableResult, "history builder should index the complete result snapshot by action")

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
        type: "短语",
        sourceText: "Selection-first interaction",
        sourceAppName: "Safari",
        sourceAction: .translate,
        resultSnapshot: LingobarResult(
            title: "翻译",
            shortcut: "⌘1",
            summary: "以选区为入口。",
            rows: [LingobarRow("短语", "selection-first")],
            sideTitle: "后续动作",
            chips: ["selection-first"],
            defaultCollectionItem: DefaultCollectionItem(title: "selection-first", note: "以选区为入口。", type: "短语")
        ),
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
    try check(collectionItem.source == "Safari", "collection item source should preserve source app")
    try check(collectionItem.itemType == "短语", "collection item type should preserve SavedPhrase type")
    try check(collectionItem.sourceText == "Selection-first interaction", "collection item should preserve source text snapshot")
    try check(collectionItem.action == .translate, "collection item should preserve source action")
    try check(collectionItem.actionID == LanguageAction.translate.actionID, "collection item should preserve source action ID")
    try check(collectionItem.actionTitle == LanguageAction.translate.title, "collection item should preserve source action title")
    try check(collectionItem.resultSnapshot == phrase.resultSnapshot, "collection item should preserve the result snapshot")

    let customActionID = "custom:88888888-8888-8888-8888-888888888888"
    let customPhrase = SavedPhrase(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888889")!,
        title: "Concise interview answer",
        note: "面试回答",
        sourceText: "raw answer",
        sourceAppName: "Notes",
        sourceActionID: customActionID,
        sourceActionTitle: "面试回答",
        resultSnapshot: phrase.resultSnapshot,
        createdAt: phraseDate
    )
    let decodedCustomPhrase = try JSONDecoder().decode(
        SavedPhrase.self,
        from: JSONEncoder().encode(customPhrase)
    )
    try check(decodedCustomPhrase.sourceActionID == customActionID, "saved custom collection should persist its action ID")
    try check(decodedCustomPhrase.sourceActionTitle == "面试回答", "saved custom collection should persist its action title")
    let customCollectionItem = LingobarHubLibrary.collectionItems(from: [decodedCustomPhrase])[0]
    try check(customCollectionItem.action == nil, "custom collection should not invent a built-in action")
    try check(customCollectionItem.actionID == customActionID, "custom collection item should preserve its descriptor ID")
    try check(customCollectionItem.actionTitle == "面试回答", "custom collection item should preserve its descriptor title")
    try check(
        customCollectionItem.resultSnapshots[customActionID]?.result == phrase.resultSnapshot,
        "custom collection snapshot should be keyed by its descriptor ID"
    )

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
    try check(historyItem.actionID == LanguageAction.examples.actionID, "history item should preserve action ID")
    try check(historyItem.actionTitle == LanguageAction.examples.title, "history item should preserve action title")
    try check(historyItem.itemType == "例句", "history item should preserve item type")
    try check(historyItem.source == "Safari", "history item should preserve source app")
    try check(historyItem.createdAt == historyDate, "history item should preserve created date")
    try check(historyItem.sourceText == "call into question", "history item should preserve source text")
    try check(historyItem.title == "call into question", "history item title should be the selected sentence, not a derived action result")
    try check(historyItem.copyText == "The report calls the timeline into question.", "history item should preserve copy text")
    try check(historyItem.resultSnapshot == history.resultSnapshot, "history item should preserve result snapshot")
    try check(historyItem.resultSnapshots["examples"]?.result == history.resultSnapshot, "history item should preserve the full action-keyed snapshot map")
}

func checkLingobarRelaunchPlanner() throws {
    let snapshot = LingobarResult(
        title: "例句",
        shortcut: "⌘4",
        summary: "The report calls the timeline into question.",
        rows: [LingobarRow("例句", "The report calls the timeline into question.")],
        sideTitle: "后续动作",
        chips: ["call into question"],
        moreActionTitle: "更多例句",
        defaultCollectionItem: DefaultCollectionItem(
            title: "The report calls the timeline into question.",
            note: "可迁移例句",
            type: "例句"
        )
    )

    try check(
        LingobarRelaunchPlanner.plan(snapshot: snapshot, sourceAction: .examples, requestedAction: nil) == .openSnapshot(LingobarStoredResultSnapshot(result: snapshot)),
        "relaunch should use the saved snapshot by default"
    )
    try check(
        LingobarRelaunchPlanner.plan(snapshot: snapshot, sourceAction: .examples, requestedAction: .examples) == .openSnapshot(LingobarStoredResultSnapshot(result: snapshot)),
        "relaunch should use the snapshot when requesting the original action"
    )
    try check(
        LingobarRelaunchPlanner.plan(snapshot: snapshot, sourceAction: .examples, requestedAction: .grammar) == .requestLLM(.grammar),
        "relaunch should request AI only when switching actions"
    )
    try check(
        LingobarRelaunchPlanner.plan(snapshot: nil, sourceAction: .rewrite, requestedAction: nil) == .requestLLM(.rewrite),
        "relaunch should request AI when no snapshot is available"
    )

    let translationSnapshot = LingobarStoredResultSnapshot(
        result: LingobarResult(
            title: "翻译",
            shortcut: "⌘1",
            summary: "译文",
            rows: [LingobarRow("通用", "译文")],
            sideTitle: "后续动作",
            chips: []
        )
    )
    let grammarSnapshot = LingobarStoredResultSnapshot(
        result: LingobarResult(
            title: "语法",
            shortcut: "⌘2",
            summary: "语法快照",
            rows: [LingobarRow("句型", "SVO")],
            sideTitle: "后续动作",
            chips: []
        ),
        grammarResult: .mockupFixture
    )
    let snapshots = [
        LanguageAction.translate.rawValue: translationSnapshot,
        LanguageAction.grammar.rawValue: grammarSnapshot
    ]
    try check(
        LingobarRelaunchPlanner.plan(snapshots: snapshots, sourceAction: .translate, requestedAction: .grammar) == .openSnapshot(grammarSnapshot),
        "relaunch should restore a requested action from the aggregate snapshot map when present"
    )
    try check(
        LingobarRelaunchPlanner.plan(snapshots: snapshots, sourceAction: .translate, requestedAction: .rewrite) == .requestLLM(.rewrite),
        "relaunch should call AI only when the requested action is missing from the aggregate snapshot map"
    )
    let customActionID = "custom:99999999-9999-9999-9999-999999999999"
    let customSnapshot = LingobarStoredResultSnapshot(
        result: LingobarResult(
            title: "面试回答",
            shortcut: "⌘1",
            summary: "Concise answer",
            rows: [LingobarRow("结果", "Concise answer")],
            sideTitle: "后续动作",
            chips: []
        )
    )
    try check(
        LingobarRelaunchPlanner.plan(
            snapshots: snapshots.merging([customActionID: customSnapshot]) { current, _ in current },
            sourceAction: .rewrite,
            sourceActionID: customActionID,
            requestedAction: nil
        ) == .openSnapshot(customSnapshot),
        "relaunch should prefer a custom source action ID over its legacy built-in fallback"
    )
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

    let runAI = try sourceRegion(source, from: "private func runAIIfAvailable", to: "private func completeAIRequest")
    try check(runAI.contains("grammarResultCache[grammarKey]"), "grammar requests should use cached results before starting AI")
    try check(runAI.contains("grammarRequests[grammarKey]"), "grammar requests should reuse in-flight work for the same text and model")
    try check(
        countOccurrences(of: "Task.detached(priority: .userInitiated)", in: runAI) == 2,
        "AI completion and grammar decoding should run off the main actor"
    )

    let completionHelper = try sourceRegion(source, from: "private func completeAIRequest", to: "private func failAIRequest")
    let successGuard = try requiredRange(
        in: completionHelper,
        needle: "guard activeAIRequestID == requestID else",
        message: "completion helper should keep the successful-decode request guard"
    )
    let recordCall = try requiredRange(
        in: completionHelper,
        needle: "recordCompletedHistory(",
        message: "completion helper should record completed history on the success path"
    )
    try check(recordCall.lowerBound > successGuard.lowerBound, "history recording should occur after the successful-decode request guard")
    let loadingComplete = try requiredRange(
        in: completionHelper,
        needle: "isLoading = false",
        message: "completion helper should end loading before writing history"
    )
    try check(loadingComplete.lowerBound < recordCall.lowerBound, "result display should unblock before history recording starts")
    try check(
        String(completionHelper[..<successGuard.lowerBound]).doesNotMentionHistoryRecording,
        "history recording should not appear before the successful-decode request guard"
    )
    try check(
        completionHelper.contains("sourceText: historySourceText") && completionHelper.contains("sourceAppName: historySourceAppName"),
        "success-path recording should use captured source text and source label"
    )
    try check(
        countOccurrences(of: "recordCompletedHistory(", in: completionHelper) == 1,
        "completion helper should call the history recording helper exactly once"
    )

    let failureHelper = try sourceRegion(source, from: "private func failAIRequest", to: "private func grammarRequestKey")
    try check(failureHelper.contains("if error is DecodingError"), "failure helper should preserve the decoding error branch")
    try check(failureHelper.doesNotMentionHistoryRecording, "catch/error paths should not record history")

    let helper = try sourceRegion(source, from: "private func recordCompletedHistory", to: "private func systemPrompt")
    try check(helper.contains("LingobarHistoryRecord.make"), "recording helper should build a compact history record")
    try check(!helper.contains("Task.detached(priority: .utility)"), "history recording should persist immediately for fast Hub visibility")
    try check(helper.contains("historyStore.append(record)"), "recording helper should append through the injected history store immediately")
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

func checkGrammarStagedDecodingRecoverySourceGate() throws {
    let sourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift")
    let source = try String(contentsOf: sourceURL, encoding: .utf8)

    let decoder = try sourceRegion(source, from: "static func decodeGrammar", to: "private static func decodeObject")
    try check(decoder.contains("grammarSpinePrompt()"), "grammar decode should start with a compact spine request")
    try check(decoder.contains("decodeGrammarSpine"), "grammar decode should recover when the first compact spine response is not JSON")
    try check(decoder.contains("GrammarResult.normalizedChunks"), "grammar spine should normalize chunks before rendering")
    try check(decoder.contains("await onSpine(partial)"), "grammar decode should publish a partial spine before slower sections finish")
    try check(
        decoder.contains("async let tokens") &&
            decoder.contains("async let dependenciesTree") &&
            decoder.contains("async let trunkOrder") &&
            decoder.contains("async let tenseVoice") &&
            decoder.contains("async let knowledge"),
        "grammar decode should split long-sentence sections into bounded parallel JSON requests"
    )

    let decodeObject = try sourceRegion(source, from: "private static func decodeObject", to: "private static func decodeStructured")
    try check(decodeObject.contains("for attempt in 0..<2"), "grammar JSON section decode should retry once on schema drift")
    try check(
        decodeObject.contains("Previous response was not valid for the requested schema"),
        "grammar JSON retry should force a schema-only response"
    )

    let runAI = try sourceRegion(source, from: "private func runAIIfAvailable", to: "private func completeAIRequest")
    try check(runAI.contains("LingobarAICompletionDecoder.decodeGrammar"), "grammar actions should use the staged grammar decoder")
    try check(runAI.contains("completeGrammarSpine"), "grammar actions should surface the staged spine result")
    try check(runAI.contains("failGrammarRequest"), "grammar actions should route failures through the grammar recovery path")

    let failGrammar = try sourceRegion(source, from: "private func failGrammarRequest", to: "private func completeAIRequest")
    try check(failGrammar.contains("if grammarResult != nil"), "grammar failures after a spine result should keep the partial panel visible")
    try check(failGrammar.contains("partial_failure"), "grammar partial failures should be recorded for diagnosis")
    try check(failGrammar.contains("语法补全失败"), "grammar partial failure status should distinguish completion failure from format failure")
}

func checkGrammarAbbreviationDisplaySourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let uiSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarUI/GrammarResultPanel.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )

    try check(
        uiSource.contains("GrammarTreeLabel(label: node.label") &&
            uiSource.contains("GrammarAbbreviationGlossary.chineseNote(for: label)"),
        "grammar tree labels should show Chinese notes for abbreviations"
    )
    try check(
        uiSource.contains("GrammarAbbreviationGlossary.displayText(for: token.pos)"),
        "grammar token POS labels should show Chinese notes for abbreviations"
    )
    try check(
        uiSource.contains("GrammarAbbreviationGlossary.displayText(for: collocation.pos)"),
        "grammar collocation POS labels should show Chinese notes for abbreviations"
    )
    try check(
        uiSource.contains("GrammarAbbreviationGlossary.displayText(for: clause.tense)") &&
            uiSource.contains("GrammarAbbreviationGlossary.displayText(for: clause.aspect)") &&
            uiSource.contains("GrammarAbbreviationGlossary.displayText(for: clause.voice)") &&
            uiSource.contains("moodBadgeText"),
        "grammar tense cards should show Chinese notes for tense/aspect/voice/mood abbreviations"
    )
    try check(
        viewModelSource.contains("do not return bare abbreviations like adv or prep") &&
            viewModelSource.contains("if using abbreviations such as S, NP, VP, AdvP, or ConjP") &&
            viewModelSource.contains("collocations.pos must not be a bare abbreviation") &&
            viewModelSource.contains("tense, aspect, voice, and mood must be readable to Chinese learners"),
        "grammar prompts should ask the AI to avoid bare abbreviations"
    )
}

func checkGrammarTabLearningSectionsSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let uiSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarUI/GrammarResultPanel.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )

    let body = try sourceRegion(uiSource, from: "public var body: some View", to: "private var selectedTabContent")
    try check(body.contains("selectedTabContent"), "grammar panel body should route selected grammar tabs through a shared tab content container")
    try check(
        body.doesNotContainAny(["patternSection", "knowledgeSection"]),
        "pattern and knowledge sections should belong to selected tab content, not sit beside the tab container"
    )

    let tabContent = try sourceRegion(uiSource, from: "private var selectedTabContent", to: "private var sentenceSection")
    try check(
        tabContent.contains("visualizationSection") &&
            tabContent.contains("patternSection") &&
            tabContent.contains("knowledgeSection"),
        "each grammar tab should include visualization, reusable pattern, and learning sections"
    )
    try check(
        tabContent.contains("grammar-tab-content-\\(selectedView.rawValue)"),
        "selected grammar tab content should expose a tab-specific accessibility identifier"
    )

    let knowledgeSection = try sourceRegion(uiSource, from: "private var knowledgeSection", to: "private func columnHead")
    try check(
        knowledgeSection.contains("固定搭配") &&
            knowledgeSection.contains("常见词组") &&
            knowledgeSection.contains("语法点"),
        "grammar tab learning section should keep collocations, phrases, and grammar points together"
    )
    try check(
        knowledgeSection.contains("grammar-tab-learning-\\(selectedView.rawValue)"),
        "grammar tab learning section should be associated with the active grammar tab"
    )

    let grammarKnowledgePrompt = try sourceRegion(viewModelSource, from: "private static func grammarKnowledgePrompt", to: "private extension KeyedDecodingContainer")
    try check(
        grammarKnowledgePrompt.contains("shared below every grammar visualization tab") &&
            grammarKnowledgePrompt.contains("annotated, dependency, tree, trunk, tense, and word-order"),
        "grammar knowledge prompt should request learning points that work across every grammar tab"
    )
}

func checkActionTabLearningInsightsSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let resultSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarCore/LingobarResult.swift"),
        encoding: .utf8
    )
    let structuredSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarCore/StructuredLingobarResult.swift"),
        encoding: .utf8
    )
    let grammarSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarCore/GrammarResult.swift"),
        encoding: .utf8
    )
    let rootViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )
    let grammarPanelSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarUI/GrammarResultPanel.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )

    try check(
        resultSource.contains("public struct LingobarLearningInsights") &&
            resultSource.contains("public var learningInsights: LingobarLearningInsights"),
        "generic Lingobar results should carry learning insights, not only grammar results"
    )
    try check(
        grammarSource.contains("public var learningInsights: LingobarLearningInsights") &&
            grammarSource.contains("func applyingLearningInsights"),
        "grammar results should expose and accept the shared learning-insight block"
    )
    try check(
        structuredSource.contains("case learningInsights") &&
            structuredSource.contains("case collocations") &&
            structuredSource.contains("decodeLearningInsights"),
        "structured AI results should decode collocations, phrases, and grammar points"
    )

    let schemaPrompt = try sourceRegion(viewModelSource, from: "let schema = ", to: "return switch action")
    try check(
        schemaPrompt.contains("Do not include learningInsights here") &&
            schemaPrompt.contains("shared from the cached grammar result") &&
            schemaPrompt.contains("every action tab shows the same learning sections"),
        "generic action prompts should not request per-tab learning insights"
    )

    let panelBodyContent = try sourceRegion(rootViewSource, from: "private var panelBodyContent", to: "private var translationVariantRows")
    try check(
        panelBodyContent.contains("shouldShowLearningInsights") &&
            panelBodyContent.contains("learningInsightsSection(viewModel.visibleLearningInsights)"),
        "generic action panels should render shared grammar-derived learning insights below normal results"
    )
    let grammarResultPanel = try sourceRegion(rootViewSource, from: "private func grammarResultPanel", to: "private func genericResultPanel")
    try check(
        grammarResultPanel.contains("learningInsightsOverride: viewModel.visibleLearningInsights,"),
        "grammar action panels should render the same shared learning insights as every other action tab, even while the shared request is still empty"
    )
    try check(
        grammarPanelSource.contains("learningInsightsOverride: LingobarLearningInsights?") &&
            grammarPanelSource.contains("displayedLearningInsights") &&
            grammarPanelSource.contains("ForEach(displayedLearningInsights.collocations)") &&
            grammarPanelSource.contains("ForEach(displayedLearningInsights.phrases)") &&
            grammarPanelSource.contains("ForEach(displayedLearningInsights.grammarPoints)"),
        "grammar result panel should allow the shared learning-insight source to replace per-result learning content"
    )

    let learningSection = try sourceRegion(rootViewSource, from: "private func learningInsightsSection", to: "private func learningColumn")
    try check(
            learningSection.contains("固定搭配") &&
            learningSection.contains("常见词组") &&
            learningSection.contains("语法点") &&
            learningSection.contains("action-learning-insights-\\(viewModel.action.id)") &&
            learningSection.contains("rows: insights.collocations.map") &&
            learningSection.contains("rows: insights.phrases.map") &&
            learningSection.contains("rows: insights.grammarPoints.map") &&
            !learningSection.contains(".prefix("),
        "generic action learning section should expose the full grammar-derived learning categories per action"
    )

    let localEngineSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarCore/LocalLanguageEngine.swift"),
        encoding: .utf8
    )
    try check(
        localEngineSource.contains("defaultLearningInsights") &&
            countOccurrences(of: "learningInsights: Self.defaultLearningInsights", in: localEngineSource) >= 5,
        "local language engine fixtures should include learning insights across language actions"
    )

    try check(
        viewModelSource.contains("@Published private(set) var sharedLearningInsights") &&
            viewModelSource.contains("var visibleLearningInsights: LingobarLearningInsights") &&
            viewModelSource.contains("grammarRequests: [GrammarRequestKey: Task<GrammarResult, Error>]") &&
            !viewModelSource.contains("learningInsightRequests") &&
            !viewModelSource.contains("decodeGrammarLearningInsights"),
        "view model should expose one shared learning-insight source backed by the full grammar cache"
    )
    let runAI = try sourceRegion(viewModelSource, from: "private func runAIIfAvailable", to: "private func completeGrammarSpine")
    try check(
        runAI.contains("if action.builtInAction != .grammar") &&
            runAI.contains("warmSharedLearningInsightsIfAvailable(for: text, aiClient: aiClient)") &&
            runAI.contains("grammarRequests[grammarKey]"),
        "non-grammar actions should warm the full grammar task while grammar actions own their visible grammar request"
    )
    let completion = try sourceRegion(viewModelSource, from: "private func completeAIRequest", to: "private func failAIRequest")
    try check(
        completion.contains("setSharedLearningInsights(from: grammar, key: grammarCacheKey)") &&
            completion.contains("rememberGrammarResult(grammar, for: grammarCacheKey)") &&
            !completion.contains("learningInsightsCache[grammarCacheKey]") &&
            !completion.contains("grammar.applyingLearningInsights(cachedInsights)") &&
            !completion.contains("setSharedLearningInsights(from: structured"),
        "grammar completions should make the full grammar result canonical for cross-tab learning insights"
    )
    let learningCache = try sourceRegion(viewModelSource, from: "private func warmSharedLearningInsightsIfAvailable", to: "private func recordCompletedHistory")
    try check(
        learningCache.contains("grammarResultCache[grammarKey]") &&
            learningCache.contains("grammarRequests[grammarKey] ?? Task.detached") &&
            learningCache.contains("LingobarAICompletionDecoder.decodeGrammar") &&
            learningCache.contains("rememberGrammarResult(grammar, for: grammarKey)") &&
            learningCache.contains("setSharedLearningInsights(from: grammar, key: grammarKey)") &&
            learningCache.contains("updateCurrentGrammarResultLearningInsights") &&
            learningCache.contains("resetSharedLearningInsights") &&
            !learningCache.contains("learningInsightsCache") &&
            !learningCache.contains("decodeGrammarLearningInsights"),
        "shared learning insights should be populated from the cached full grammar request and applied to grammar snapshots"
    )
    let grammarCache = try sourceRegion(viewModelSource, from: "private func rememberGrammarResult", to: "private func setSharedLearningInsights(from grammar")
    try check(
        grammarCache.contains("setSharedLearningInsights(from: grammar, key: key)") &&
            !grammarCache.contains("rememberLearningInsights"),
        "full grammar results should be the canonical cross-tab learning cache"
    )
}

func checkFollowUpThreadMemorySourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )
    let rootViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )

    try check(
        viewModelSource.contains("struct LingobarFollowUpExchange") &&
            viewModelSource.contains("@Published var followUpThread: [LingobarFollowUpExchange]"),
        "follow-up pane should keep a thread of exchanges instead of a single question/answer pair"
    )

    let contextSnapshot = try sourceRegion(viewModelSource, from: "private struct LingobarFollowUpContextSnapshot", to: "struct LingobarFollowUpExchange")
    try check(
        contextSnapshot.contains("conversation: [LingobarFollowUpConversationTurn]"),
        "follow-up context snapshot should carry previous conversation turns"
    )

    let followUpPrompt = try sourceRegion(viewModelSource, from: "private static func systemPrompt(context:", to: "private struct GrammarRequestKey")
    try check(
        followUpPrompt.contains("Use previous follow-up turns as conversation memory") &&
            followUpPrompt.contains("Previous follow-up turns:"),
        "follow-up prompt should include previous turns as conversational memory"
    )

    let submitFollowUp = try sourceRegion(viewModelSource, from: "func submitFollowUp", to: "func copyFollowUpAnswer")
    try check(
        submitFollowUp.contains("let context = followUpContextSnapshot()") &&
            submitFollowUp.contains("appendFollowUpExchange") &&
            submitFollowUp.contains("activeFollowUpExchangeID"),
        "follow-up submit should capture prior context, append a new exchange, and track the active exchange"
    )

    let togglePane = try sourceRegion(viewModelSource, from: "func toggleFollowUpPane", to: "func closeFollowUp")
    try check(
        !togglePane.contains("resetFollowUpThread()") &&
            togglePane.contains("if !hasFollowUpExchange"),
        "opening the follow-up pane should preserve the current session thread"
    )
    let closePane = try sourceRegion(viewModelSource, from: "func closeFollowUp", to: "func toggleFollowUpContextAnchor")
    try check(
        !closePane.contains("resetFollowUpThread()"),
        "closing the follow-up pane should hide it without clearing the current session thread"
    )
    let toggleAnchor = try sourceRegion(viewModelSource, from: "func toggleFollowUpContextAnchor", to: "func submitFollowUp")
    try check(
        !toggleAnchor.contains("resetFollowUpThread()"),
        "toggling follow-up context anchoring should not erase the current session thread"
    )
    let performAction = try sourceRegion(viewModelSource, from: "func perform", to: "func submitInput")
    try check(
        !performAction.contains("resetFollowUpThread()"),
        "switching language actions should preserve the current Lingobar session thread"
    )

    let followUpHelpers = try sourceRegion(viewModelSource, from: "private func resetFollowUpSession", to: "private static func followUpRevealChunks")
    try check(
        followUpHelpers.contains("followUpThread = []") &&
            followUpHelpers.contains("resetFollowUpSession") &&
            followUpHelpers.contains("closeFollowUp(sendsLayoutChange: sendsLayoutChange)") &&
            followUpHelpers.contains("followUpConversationContext()") &&
            followUpHelpers.contains(".suffix(6)") &&
            followUpHelpers.contains("updateFollowUpExchange"),
        "follow-up helpers should reset, summarize, and update the multi-turn thread"
    )

    let followUpThreadView = try sourceRegion(rootViewSource, from: "private var followUpThread", to: "private var followUpEmptyState")
    try check(
        followUpThreadView.contains("ForEach(viewModel.followUpThread)") &&
            followUpThreadView.contains("followUpExchange(exchange)"),
        "follow-up pane should render every exchange in the thread"
    )

    let followUpMessageViews = try sourceRegion(rootViewSource, from: "private func followUpExchange", to: "private var followUpComposer")
    try check(
        followUpMessageViews.contains("exchange.question") &&
            followUpMessageViews.contains("exchange.answer") &&
            followUpMessageViews.contains("copyFollowUpAnswer(exchangeID: exchange.id)") &&
            followUpMessageViews.contains("collectFollowUpAnswer(exchangeID: exchange.id)"),
        "follow-up message controls should operate on the selected exchange, not only the latest answer"
    )
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
    let firstDate = Date(timeIntervalSince1970: 1_710_000_400)
    let secondDate = Date(timeIntervalSince1970: 1_710_000_401)
    let snapshot = LingobarResult(
        title: "例句",
        shortcut: "⌘4",
        summary: "The report calls the timeline into question.",
        rows: [LingobarRow("例句", "The report calls the timeline into question.")],
        sideTitle: "后续动作",
        chips: ["call into question"],
        moreActionTitle: "更多例句",
        defaultCollectionItem: DefaultCollectionItem(
            title: "The report calls the timeline into question.",
            note: "可迁移例句",
            type: "例句"
        )
    )
    let phrases = [
        SavedPhrase(
            title: "selection-first",
            note: "以选区为入口。",
            type: "短语",
            sourceText: "Selection-first interaction",
            sourceAppName: "Safari",
            sourceAction: .translate,
            resultSnapshot: snapshot,
            createdAt: firstDate
        ),
        SavedPhrase(
            title: "learning object",
            note: "可拆解、可复用。",
            type: "文本",
            sourceText: "learning object",
            sourceAppName: "Lingobar",
            sourceAction: .examples,
            resultSnapshot: snapshot,
            createdAt: secondDate
        )
    ]

    try store.save(phrases)
    let loaded = try store.load()
    try check(loaded == phrases, "saved phrases should persist type, source snapshot, action, and result snapshot")

    let legacyFileURL = directory.appending(path: "legacy-phrases.json")
    let legacyJSON = """
    [
      {
        "title": "legacy phrase",
        "note": "old compact card"
      }
    ]
    """
    try Data(legacyJSON.utf8).write(to: legacyFileURL, options: [.atomic])
    let legacy = try PhraseStore(fileURL: legacyFileURL).load()
    try check(legacy.count == 1, "legacy title/note phrase files should decode")
    try check(legacy[0].title == "legacy phrase", "legacy phrase title should decode")
    try check(legacy[0].note == "old compact card", "legacy phrase note should decode")
    try check(legacy[0].type == "文本", "legacy phrase type should default to 文本")
    try check(legacy[0].sourceAppName == "Lingobar", "legacy phrase source should default to Lingobar")
    try check(legacy[0].resultSnapshot == nil, "legacy phrase should not invent a result snapshot")
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
    let settingsViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/SettingsView.swift"),
        encoding: .utf8
    )
    let appVersionSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/AppVersion.swift"),
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
    try check(viewSource.contains("HubSettingsSubnavButton"), "Hub settings should use the reference-style horizontal subnav")
    try check(
        appVersionSource.contains("CFBundleShortVersionString") &&
            appVersionSource.contains("CFBundleVersion"),
        "app version helper should read release metadata from the bundle Info.plist"
    )
    try check(
        viewSource.contains("AppVersion.displayString") &&
            settingsViewSource.contains("AppVersion.displayString"),
        "Hub and legacy Settings about sections should show the real packaged app version"
    )
    try check(!settingsViewSource.contains("版本 0.1.0"), "about section should not hard-code the prototype version")
    try check(viewSource.contains("ScrollView(.horizontal, showsIndicators: false)"), "Hub settings subnav should remain horizontal")
    try check(viewSource.contains("LINGOPEEK_OPEN_HUB_SETTINGS_SECTION"), "Hub settings should support deterministic subsection launch")
    try check(
        viewSource.contains("NSApplication.didBecomeActiveNotification") && viewSource.contains("state.refreshSettings()"),
        "Hub settings should refresh external permission state when the app becomes active"
    )
    try check(
        viewSource.contains("permissionRefreshTimer") &&
            viewSource.contains("state.selectedSettingsSectionID == .permissions") &&
            viewSource.contains("state.refreshSettings()"),
        "Hub permissions section should poll system Accessibility status while visible"
    )
    try check(
        viewSource.contains("libraryRefreshTimer = Timer.publish(every: 5") &&
            viewSource.contains("state.refreshLibrary()"),
        "Hub should refresh collection and history state every five seconds while open"
    )
    try check(
        settingsViewSource.contains("NSApplication.didBecomeActiveNotification") && settingsViewSource.contains("refreshSettings()"),
        "legacy Settings scene should refresh external permission state when the app becomes active"
    )
    try check(
        settingsViewSource.contains("permissionRefreshTimer") &&
            settingsViewSource.contains("selectedSection == .permissions") &&
            settingsViewSource.contains("refreshSettings()"),
        "legacy permissions section should poll system Accessibility status while visible"
    )
    try check(
        windowSource.contains("Self.openAccessibilitySettings()") && windowSource.contains("state.refreshSettings()"),
        "opening Accessibility settings from the Hub should immediately refresh the local permission snapshot"
    )
    try check(
        controllerSource.contains("Self.openAccessibilitySettings()") && controllerSource.contains("refreshRuntimeSettings()"),
        "opening Accessibility settings from the setup gate should immediately refresh runtime permission state"
    )
    try check(viewSource.contains("private static let schemeGridColumns"), "Hub settings appearance schemes should use the reference two-column grid")
    try check(viewSource.contains("Button(\"保存\")"), "Hub API key editing should expose a visible save button")
    try check(viewSource.contains("state.hasPendingTokenDraft"), "Hub API key save button should track pending token input")
    try check(viewSource.contains("HubTokenInputField"), "Hub API key field should use a readable dedicated token input")
    try check(viewSource.contains("HubHotKeyRecorder("), "Hub settings should allow recording the Lingobar trigger hotkey")
    try check(viewSource.contains("func saveHotKey(_ hotKey: LingobarHotKey)"), "Hub settings should persist recorded hotkeys")
    try check(!viewSource.contains("HubSettingsHeader(title: \"通用\""), "Hub settings should not add duplicate per-section title headers")
    try check(viewSource.contains("PhraseStore.defaultStore()"), "Hub collection should use the real phrase store")
    try check(viewSource.contains("LingobarHistoryStore.defaultStore()"), "Hub history should use the real history store")
    try check(viewSource.contains("LingobarHubLibrary.collectionItems"), "Hub should map saved phrases through the shared library adapter")
    try check(viewSource.contains("LingobarHubLibrary.historyItems"), "Hub should map history records through the shared library adapter")
    let hubContentSwitch = try sourceRegion(viewSource, from: "private var content: some View", to: "private struct HubSidebar")
    let historyContent = try sourceRegion(hubContentSwitch, from: "case .history:", to: "case .settings:")
    try check(historyContent.contains("HubHistoryPane("), "Hub history should use a dedicated flat history list")
    try check(historyContent.contains("onSelect: state.select"), "Hub history should wire row selection into Hub state")
    try check(!historyContent.contains("onClear"), "Hub history should not expose a top-level clear-all action")
    try check(!historyContent.contains("LibraryPane("), "Hub history should not reuse the collection library pane")
    try check(!historyContent.contains("historyTypeOptions"), "Hub history should not expose collection-style type filters")
    try check(!historyContent.contains("HubSearchField("), "Hub history should render as a flat list without collection search controls")
    let historyPane = try sourceRegion(viewSource, from: "private struct HubHistoryPane", to: "private struct HubHistoryRow: View")
    try check(
        historyPane.contains("private var historyRows: [HubHistoryDisplayRow]") &&
            historyPane.contains("items.map(HubHistoryDisplayRow.init)") &&
            historyPane.contains("private func item(with id: UUID)") &&
            historyPane.contains("ForEach(historyRows)") &&
            !historyPane.contains("ForEach(items)"),
        "Hub history pane should render lightweight row models and resolve full snapshot items by id only for actions"
    )
    let historyRow = try sourceRegion(viewSource, from: "private struct HubHistoryRow: View", to: "private struct HubHistoryBlock")
    try check(
        historyRow.contains("var item: HubHistoryDisplayRow") &&
            historyRow.contains("var onSelect: (UUID) -> Void") &&
            !historyRow.contains("var item: LingobarHubLibraryItem"),
        "Hub history rows should carry only lightweight display data and id-based callbacks"
    )
    try check(
        historyRow.contains(".contentShape(") && historyRow.contains(".simultaneousGesture(TapGesture().onEnded"),
        "Hub history rows should select reliably from the whole row body, even when text selection is enabled"
    )
    try check(
        historyRow.contains("@State private var isHovered") &&
            historyRow.contains(".onHover { isHovered = $0 }") &&
            historyRow.contains("rowFill") &&
            historyRow.contains("rowStroke"),
        "Hub history rows should expose hover color feedback"
    )
    let historyRowFill = try sourceRegion(historyRow, from: "private var rowFill", to: "private var rowStroke")
    let historyRowStroke = try sourceRegion(historyRow, from: "private var rowStroke", to: "var body: some View")
    try check(
        historyRowFill.contains("return isHovered ? HubColor.selectedFill : HubColor.card") &&
            !historyRowFill.contains("if isSelected"),
        "Hub history row fill should be blue only while hovered, not while selected"
    )
    try check(
        historyRowStroke.contains("return isHovered ? HubColor.accent.opacity(0.5) : HubColor.hairline") &&
            !historyRowStroke.contains("if isSelected"),
        "Hub history row stroke should be accented only while hovered, not while selected"
    )
    try check(historyRow.contains(".textSelection(.enabled)"), "Hub history list text should remain selectable")
    try check(!historyRow.contains("item.resultSnapshot?.rows"), "Hub history rows should not render full result snapshot rows inline")
    try check(!historyRow.contains("HubHistoryBlock("), "Hub history rows should keep the visible list to the selected sentence")
    try check(historyRow.contains("HStack(spacing: 7)"), "Hub history row actions should be horizontal to keep rows compact")
    try check(!historyRow.contains("VStack(spacing: 7)"), "Hub history row actions should not be stacked vertically")
    try check(historyRow.contains("\"doc.on.doc\""), "Hub history rows should expose a copy action")
    try check(historyRow.contains("\"arrow.up.forward.square\""), "Hub history rows should expose a trailing button to open the full snapshot")
    try check(historyRow.contains("\"bookmark\""), "Hub history rows should expose a trailing save button")
    try check(historyRow.contains("\"trash\""), "Hub history rows should expose a trailing delete button")
    let collectionCard = try sourceRegion(viewSource, from: "private struct HubLibraryCard", to: "private struct HubItemDetailPane")
    try check(
        collectionCard.contains("@State private var isHovered") &&
            collectionCard.contains(".onHover { isHovered = $0 }") &&
            collectionCard.contains("cardFill") &&
            collectionCard.contains("cardStroke"),
        "Hub collection cards should expose the same hover color feedback"
    )
    let collectionCardFill = try sourceRegion(collectionCard, from: "private var cardFill", to: "private var cardStroke")
    let collectionCardStroke = try sourceRegion(collectionCard, from: "private var cardStroke", to: "var body: some View")
    try check(
        collectionCardFill.contains("return isHovered ? HubColor.selectedFill : HubColor.card") &&
            !collectionCardFill.contains("if isSelected"),
        "Hub collection card fill should be blue only while hovered, not while selected"
    )
    try check(
        collectionCardStroke.contains("return isHovered ? HubColor.accent.opacity(0.5) : HubColor.hairline") &&
            !collectionCardStroke.contains("if isSelected"),
        "Hub collection card stroke should be accented only while hovered, not while selected"
    )
    try check(collectionCard.contains(".textSelection(.enabled)"), "Hub collection list text should remain selectable")
    let detailBlock = try sourceRegion(viewSource, from: "private struct HubDetailBlock", to: "private struct HubEmptyState")
    try check(detailBlock.contains(".textSelection(.enabled)"), "Hub detail text should remain selectable after list rows stop selecting text")
    try check(!viewSource.contains("\"清空历史\""), "Hub should not render a dangerous clear-all history button")
    try check(controllerSource.contains("hubWindowController.show(section: .settings)"), "settings entry points should open the Hub settings section")
    try check(controllerSource.contains("appActivationObserver"), "controller should observe app activation for external setup state changes")
    try check(controllerSource.contains("private func refreshRuntimeSettings()"), "controller should centralize runtime settings refresh")
    try check(
        controllerSource.contains("viewModel.setupGateStatus = AppSettings.setupGateStatus"),
        "controller activation refresh should update the setup gate status"
    )
    try check(controllerSource.contains("hubWindowController.show(section: .collection)"), "menu should expose the Hub collection entry")
    try check(controllerSource.contains("presentFromHub(_ item: LingobarHubLibraryItem)"), "Hub detail items should be able to relaunch Lingobar")
    let hubRelaunchCallback = try sourceRegion(windowSource, from: "onRelaunch: { [weak self] item in", to: "self.window = window")
    try check(
        !hubRelaunchCallback.contains("self?.close()"),
        "relaunching a Hub snapshot should keep the Hub window visible"
    )
    try check(!controllerSource.contains("settingsWindowController.show()"), "old settings window should not remain the active settings route")
    try check(appDelegateSource.contains("LINGOPEEK_OPEN_HUB"), "app launch should support deterministic Hub UI smoke tests")
    try check(appDelegateSource.contains("LINGOPEEK_OPEN_HUB_SECTION"), "Hub launch should support deterministic section routing")

    let rootViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )
    let actionBar = try sourceRegion(rootViewSource, from: "private var actionBar: some View", to: "private func panelTitle")
    try check(actionBar.contains("viewModel.status"), "Lingobar action bar should render status feedback for save actions")
    try check(actionBar.contains("viewModel.isActionHighlighted(action)"), "Lingobar action bar should let saved state highlight the save button")
    try check(
        !actionBar.contains("highlighted ? .semibold : .medium") &&
            actionBar.contains(".frame(width: actionButtonIconWidth)") &&
            actionBar.contains(".frame(width: actionButtonContentWidth"),
        "Lingobar action labels should keep stable width and font weight when highlighted changes"
    )
    try check(
        actionBar.contains("viewModel.recentCollectedPhraseID") &&
            actionBar.contains("onOpenCollection(collectedPhraseID)"),
        "Lingobar action bar should expose a clickable handoff to the newly collected Hub card"
    )
    try check(
        controllerSource.contains("onOpenCollection:") &&
            controllerSource.contains("hubWindowController.show(section: .collection, selectedCollectionID: collectedPhraseID)"),
        "collection success handoff should open Hub collection with the new phrase selected"
    )
    let collectFragmentHelper = try sourceRegion(viewModelSource, from: "func collectFragment", to: "func saveCurrentHistorySnapshot")
    try check(
        viewModelSource.contains("@Published var recentCollectedPhraseID: UUID?") &&
            collectFragmentHelper.contains("recentCollectedPhraseID = phrase.id"),
        "view model should publish the newest collected phrase id for the Hub handoff"
    )
    let collectableResultBlock = try sourceRegion(rootViewSource, from: "private struct CollectableResultBlock", to: "private struct SelectableResultText")
    try check(collectableResultBlock.contains("HStack(alignment: .top"), "result collect affordances should live in a trailing layout slot")
    try check(!collectableResultBlock.contains("ZStack(alignment: .topTrailing)"), "result collect affordances should not overlay the content's top-right corner")
    try check(collectableResultBlock.contains(".frame(width: 28"), "result collect affordances should reserve a stable trailing action slot")
    let selectableText = try sourceRegion(rootViewSource, from: "private struct SelectableResultText", to: "private struct InlineSelectionToolbar")
    try check(selectableText.contains("anchor.y + toolbarHeight / 2 + 10"), "inline selection toolbar should appear below the selected text instead of colliding with trailing actions")
    let grammarPanelSource = try String(
        contentsOf: root.appending(path: "Sources/LingobarUI/GrammarResultPanel.swift"),
        encoding: .utf8
    )
    let grammarCollectableBlock = try sourceRegion(grammarPanelSource, from: "private struct GrammarCollectableBlock", to: "private struct GrammarWrapLayout")
    try check(grammarCollectableBlock.contains("HStack(alignment: .top"), "grammar collect affordances should live in a trailing layout slot")
    try check(!grammarCollectableBlock.contains("ZStack(alignment: .topTrailing)"), "grammar collect affordances should not overlay speaker buttons or grammar cards")
    try check(grammarPanelSource.contains("fixedSize(horizontal: false, vertical: true)"), "grammar point cards should use content-driven height")
    let grammarPointCard = try sourceRegion(grammarPanelSource, from: "private struct GrammarPointCard", to: "private struct GrammarCollectableBlock")
    try check(grammarPointCard.contains(".overlay(alignment: .leading)"), "grammar point accent bars should not participate in height negotiation")
    let saveHelper = try sourceRegion(
        viewModelSource,
        from: "func saveCurrentHistorySnapshot",
        to: "func copyResult"
    )
    try check(viewModelSource.contains("currentHistoryRecord?.isSaved == true"), "save button highlighting should be based on the current saved history state")
    try check(saveHelper.contains("let savedRecords = try historyStore.saveOrAppend(savedRecord)"), "saving from the main panel should read back saved history state")
    try check(saveHelper.contains("currentHistoryRecord = savedRecords.first"), "saving from the main panel should refresh the current saved record immediately")
}

func checkLingobarPanelSpaceBehaviorSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let controllerSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarController.swift"),
        encoding: .utf8
    )
    let panelSetup = try sourceRegion(controllerSource, from: "private func ensurePanel()", to: "private var contentSize")

    try check(
        panelSetup.contains(".moveToActiveSpace"),
        "Lingobar panel should move to the active Space only when shown"
    )
    try check(
        !panelSetup.contains(".canJoinAllSpaces"),
        "Lingobar panel should not join all Spaces because grammar expansion must not jump back to the selected-text desktop"
    )
}

func checkLingobarInputModeIssue9SourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let rootViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )

    let submitInput = try sourceRegion(viewModelSource, from: "func submitInput()", to: "func isAvailable")
    try check(
        submitInput.contains("let submittedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)"),
        "input submit should capture the current trimmed input before routing to rewrite"
    )
    try check(submitInput.contains("activeResultSnapshots = [:]"), "input submit should clear stale rewrite snapshots before a new request")
    try check(submitInput.contains("currentHistoryRecord = nil"), "input submit should detach the previous result's saved-history state")
    try check(submitInput.contains("perform(action)"), "input submit should route non-empty input to the currently selected input action")
    try check(
        viewModelSource.contains("func selectInputAction(_ descriptor: LingobarActionDescriptor)") &&
            viewModelSource.contains("descriptor.isResultProducing"),
        "input mode should allow explicit result-producing action selection while defaulting to rewrite"
    )

    let inputPill = try sourceRegion(rootViewSource, from: "private var inputPill", to: "private var inputPlaceholder")
    try check(
        inputPill.contains(".frame(maxWidth: .infinity, alignment: .topLeading)") &&
            inputPill.contains(".frame(height: 46, alignment: .topLeading)"),
        "input field should use a stable available-width frame instead of resizing while typing"
    )
    try check(!inputPill.contains("inputFieldWidth"), "input pill should not depend on per-keystroke measured text width")
    try check(!rootViewSource.contains("private var inputFieldWidth"), "input width measurement helper should be removed to avoid horizontal jitter")

    let inputResultPanel = try sourceRegion(rootViewSource, from: "private var inputResultPanel", to: "private func resultPanel")
    try check(
        inputResultPanel.contains("panelBody(height: 244, scrolls: false)") &&
            inputResultPanel.contains("resultFooter"),
        "input results should use a non-scrolling panel body that leaves room for the footer actions"
    )
    let controllerSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarController.swift"),
        encoding: .utf8
    )
    try check(
        controllerSource.contains("inputResultPanelSize = NSSize(width: 720, height: 420)") &&
            rootViewSource.contains("viewModel.showsResult ? 420 : 72"),
        "input result panel height should fit normal rewrite rows without a scrollbar"
    )

    let resultBody = try sourceRegion(rootViewSource, from: "private var resultBody", to: "private func resultRow")
    try check(
        resultBody.contains("rewritePrimaryText") &&
            resultBody.contains("rewriteVariantRows"),
        "rewrite input mode should promote the primary rewrite and keep variants separate"
    )
    let rewritePrimaryHelpers = try sourceRegion(rootViewSource, from: "private var rewritePrimaryCard", to: "private func translationVariant")
    try check(
        rewritePrimaryHelpers.contains("rewriteSummaryLooksLikeMetaText") &&
            rewritePrimaryHelpers.contains("containsCJKCharacters(viewModel.result.summary)") &&
            rewritePrimaryHelpers.contains("isRewritePrimaryLabel"),
        "rewrite UI should avoid showing AI meta summaries as the highlighted result"
    )
    let rewritePrompt = try sourceRegion(viewModelSource, from: "case .rewrite:", to: "case .grammar:")
    try check(
        rewritePrompt.contains("summary, every rows[].value, and defaultCollectionItem.title MUST be English-only") &&
            rewritePrompt.contains("do not answer the user's question") &&
            rewritePrompt.contains("Do not include Chinese characters in summary, rows[].value, or defaultCollectionItem.title"),
        "rewrite prompt should force English-only rewrite values instead of answering or translating into Chinese"
    )
    let structuredDecoder = try sourceRegion(viewModelSource, from: "private static func decodeStructured", to: "private static func makePartialGrammar")
    try check(
        structuredDecoder.contains("validateStructuredResult(result, action: action)") &&
            structuredDecoder.contains("Rewrite response values must be English-only") &&
            structuredDecoder.contains("containsCJKCharacters"),
        "rewrite decoder should reject Chinese content values before they reach the UI"
    )

    let panelBody = try sourceRegion(rootViewSource, from: "private func panelBody", to: "private var firstChip")
    try check(panelBody.contains("scrolls: Bool = true"), "selection panels should keep scroll support as the default")
    try check(
        panelBody.contains("if scrolls") && panelBody.contains("ScrollView") && panelBody.contains("panelBodyContent"),
        "panel body should have explicit scroll and non-scroll rendering paths"
    )

    let inputTextView = try sourceRegion(rootViewSource, from: "private struct LingobarInputTextView", to: "private final class LingobarInputNSTextView")
    try check(
        inputTextView.contains("guard textView.string.isEmpty else"),
        "input text centering should not keep recalculating vertical inset for non-empty text"
    )
    try check(
        inputTextView.contains("NSSize(width: 0, height: 12)"),
        "non-empty input should keep a stable text inset while the user types"
    )
}

func checkSelectionPermissionSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let selectionReaderSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/SelectionReader.swift"),
        encoding: .utf8
    )
    let appSettingsSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/AppSettings.swift"),
        encoding: .utf8
    )
    let lingobarRootSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )

    try check(selectionReaderSource.contains("private static var canReadSelection"), "selection reader should centralize its permission gate")
    try check(selectionReaderSource.contains("AXIsProcessTrusted()"), "selection reader should ask the system Accessibility trust API")
    try check(
        selectionReaderSource.contains("AXUIElementGetTypeID()") &&
            selectionReaderSource.contains("AXValueGetTypeID()") &&
            !selectionReaderSource.contains("as!"),
        "selection reader should reject unexpected Accessibility payload types instead of force-casting them"
    )
    try check(
        selectionReaderSource.contains("LINGOPEEK_UI_TEST_MODE") &&
            selectionReaderSource.contains("LINGOPEEK_UI_TEST_SELECTION_FILE"),
        "selection reader should expose a UI-test-only selection source for deterministic launcher lifecycle checks"
    )
    try check(
        selectionReaderSource.contains("guard Self.canReadSelection else") &&
            selectionReaderSource.contains("selectedTextByCopyingSelection"),
        "selection reader should refuse AX and copy fallback reads when Accessibility is disabled"
    )
    try check(appSettingsSource.contains("private static var isUITestRuntime"), "UI test runtime detection should be explicit")
    try check(
        appSettingsSource.contains("guard isUITestRuntime else") &&
            appSettingsSource.contains("UserDefaults.standard.bool(forKey: \"LINGOPEEK_UI_TEST_BYPASS_SETUP\")"),
        "persisted setup bypass should only apply in UI test runtimes"
    )
    try check(appSettingsSource.contains("accessibilityRuntimeIdentityNote"), "settings should expose the current Accessibility runtime identity")
    try check(appSettingsSource.contains("/.build/"), "runtime identity note should detect SwiftPM debug executables")
    try check(appSettingsSource.contains("SecCodeCopySigningInformation"), "runtime identity note should inspect the current app signing identity")
    try check(appSettingsSource.contains("Developer ID/Team"), "runtime identity note should explain unstable local app signing")
    try check(
        lingobarRootSource.contains("AppSettings.accessibilityRuntimeIdentityNote") &&
            lingobarRootSource.contains("viewModel.setupGateStatus.accessibilityPermissionGranted"),
        "setup gate should surface runtime identity diagnostics when Accessibility is still missing"
    )
    let setupPanel = try sourceRegion(lingobarRootSource, from: "private var setupPanel: some View", to: "private var selectionPill")
    try check(
        setupPanel.contains("dragSurface()"),
        "setup gate panel should expose a draggable background like the normal Lingobar surfaces"
    )
}

func checkIssue15CustomActionSourceGate() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let appSettingsSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/AppSettings.swift"),
        encoding: .utf8
    )
    let hotKeySource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/HotKeyManager.swift"),
        encoding: .utf8
    )
    let controllerSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarController.swift"),
        encoding: .utf8
    )
    let hubSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarHubView.swift"),
        encoding: .utf8
    )
    let rootViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarRootView.swift"),
        encoding: .utf8
    )
    let settingsViewSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/SettingsView.swift"),
        encoding: .utf8
    )
    let viewModelSource = try String(
        contentsOf: root.appending(path: "Sources/LingoPeekApp/LingobarViewModel.swift"),
        encoding: .utf8
    )
    let selectionLauncherSource = try sourceRegion(
        rootViewSource,
        from: "private var selectionLauncher: some View",
        to: "private var inputPill: some View"
    )
    let selectionPollingSource = try sourceRegion(
        controllerSource,
        from: "private func startSelectionPolling()",
        to: "private var isLingoPeekFrontmost"
    )
    let inputResultPanelSource = try sourceRegion(
        rootViewSource,
        from: "private var inputResultPanel: some View",
        to: "private func resultPanel"
    )

    try check(
        appSettingsSource.contains("customPromptActionsKey") &&
            appSettingsSource.contains("saveCustomPromptAction") &&
            appSettingsSource.contains("deleteCustomPromptAction") &&
            appSettingsSource.contains("aiAccessConfigured: true") &&
            appSettingsSource.contains("defaultEnglishActionIDKey") &&
            appSettingsSource.contains("defaultChineseMixedActionIDKey"),
        "settings persistence should include custom prompt actions and action-ID defaults"
    )
    try check(
        hubSource.contains("自定义 Prompt 动作") &&
            hubSource.contains("HubSegmentedDescriptorRow") &&
            hubSource.contains("deleteCustomPromptAction") &&
            hubSource.contains("saveDefaultEnglishActionID"),
        "Hub settings should expose custom action create/delete and descriptor defaults"
    )
    try check(
        settingsViewSource.contains("自定义 Prompt 动作") &&
            settingsViewSource.contains("DescriptorActionMenu") &&
            settingsViewSource.contains("saveCustomPromptAction") &&
            settingsViewSource.contains("selectionHotKeyBinding"),
        "standalone SettingsView should expose custom action create/delete, descriptor defaults, and separate selection hotkey"
    )
    try check(
        hotKeySource.contains("callbacks: [UInt32") &&
            hotKeySource.contains("GetEventParameter") &&
            hotKeySource.contains("hotKeyID.id"),
        "global hotkey manager should dispatch multiple hotkeys by Carbon hotkey ID"
    )
    try check(
        controllerSource.contains("presentInputFromHotKey") &&
            controllerSource.contains("presentSelectionFromHotKey") &&
            controllerSource.contains("presentSelectionLauncher") &&
            controllerSource.contains("LINGOPEEK_UI_TEST_INPUT") &&
            controllerSource.contains("LINGOPEEK_UI_TEST_LAUNCHER") &&
            controllerSource.contains("selectedTextIncludingClipboardFallback") &&
            controllerSource.contains("selectionReader.selectedText()"),
        "controller should separate input hotkey, selection hotkey, launcher, and AX-only hover reads"
    )
    try check(
        controllerSource.contains("LingobarActionCatalog.matchingKeyboardShortcut") &&
            controllerSource.contains("descriptors: AppSettings.actionDescriptors") &&
            !controllerSource.contains("actionOrder: AppSettings.actionOrder"),
        "panel shortcuts should follow the visible built-in and custom action descriptor order"
    )
    try check(
        viewModelSource.contains("presentRecentSelectionHistoryOrExample") &&
            viewModelSource.contains("recentSelectionHistoryRecord") &&
            viewModelSource.contains("defaultExampleSelection"),
        "view model should support no-selection fallback to recent selection history or example text"
    )
    try check(
        viewModelSource.contains("snapshotActionDescriptor") &&
            viewModelSource.contains("sourceActionTitle: record.actionTitle") &&
            viewModelSource.contains("自定义动作已删除，无法重新生成") &&
            controllerSource.contains("sourceActionID: item.actionID") &&
            controllerSource.contains("sourceActionTitle: item.actionTitle") &&
            hubSource.contains("item.actionTitle"),
        "saved custom action snapshots should reopen and render with their persisted identity"
    )
    try check(
        rootViewSource.contains("selectionLauncher") &&
            rootViewSource.contains("updateSelectedText") &&
            rootViewSource.contains("selectInputAction") &&
            rootViewSource.contains("viewModel.openFromLauncher"),
        "root view should expose launcher actions, editable selected text, and input action selection"
    )
    try check(
        !selectionLauncherSource.contains("viewModel.selectedText") &&
            rootViewSource.contains("viewModel.mode == .launcher ? Self.launcherWidth : Self.mainWidth"),
        "selection launcher should keep the selected text private in a compact root surface"
    )
    try check(
        controllerSource.contains("private static let selectionPollInterval: TimeInterval = 0.15") &&
            selectionPollingSource.contains("NSEvent.addGlobalMonitorForEvents") &&
            selectionPollingSource.contains(".leftMouseUp") &&
            selectionPollingSource.contains(".keyUp") &&
            controllerSource.contains("NSEvent.removeMonitor"),
        "selection launcher should react immediately to selection gestures and clean up its event monitor"
    )
    try check(
        !selectionPollingSource.contains("pendingLauncherSelection") &&
            !selectionPollingSource.contains("stableSelectionPollCount"),
        "selection launcher should not delay presentation for repeated stable polls"
    )
    try check(
        selectionPollingSource.contains("hideSelectionLauncher()") &&
            selectionPollingSource.contains("emptySelectionPollCount >= 2") &&
            !selectionPollingSource.contains("panel?.isVisible == true, viewModel.mode != .launcher"),
        "selection polling should hide a confirmed stale launcher and continue while the full Lingobar is visible"
    )
    try check(
        inputResultPanelSource.contains("panelTitle(viewModel.action.title"),
        "input result panel should identify the selected built-in or custom action"
    )
}

do {
    try checkLocalLanguageEngine()
    try checkLanguageActionKeyboardShortcuts()
    try checkLingobarActionDescriptorCatalog()
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
    try checkGrammarAbbreviationGlossary()
    try checkGrammarChunkNormalization()
    try checkLanguageActionCodable()
    try checkLingobarHistoryStore()
    try checkLingobarHistoryRecordBuilderPrivacy()
    try checkCustomPromptActionHistorySnapshot()
    try checkLingobarHubLibraryItems()
    try checkLingobarRelaunchPlanner()
    try checkLingobarViewModelHistoryRecordingSourceGate()
    try checkGrammarStagedDecodingRecoverySourceGate()
    try checkGrammarAbbreviationDisplaySourceGate()
    try checkGrammarTabLearningSectionsSourceGate()
    try checkActionTabLearningInsightsSourceGate()
    try checkFollowUpThreadMemorySourceGate()
    try checkSelectionPermissionSourceGate()
    try checkIssue15CustomActionSourceGate()
    try checkPhraseStore()
    try checkLingobarHubShellSourceGate()
    try checkLingobarPanelSpaceBehaviorSourceGate()
    try checkLingobarInputModeIssue9SourceGate()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
