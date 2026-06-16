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
    try check(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token", "OpenAI-compatible request should use bearer token")
    try check(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "OpenAI-compatible request should send JSON")

    guard let body = request.httpBody else {
        throw CheckFailure.failed("OpenAI-compatible request should have an HTTP body")
    }
    let decoded = try JSONDecoder().decode(OpenAIChatRequest.self, from: body)
    try check(decoded.model == "deepseek-chat", "OpenAI-compatible request should keep configured model")
    try check(decoded.messages.map(\.role) == ["system", "user"], "OpenAI-compatible request should include system and user messages")
    try check(decoded.messages.last?.content == "hello", "OpenAI-compatible request should keep user content")
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
    try checkDeepSeekRequestFactory()
    try checkOpenAICompatibleRequestFactory()
    try checkSetupGate()
    try checkAIProviderConfiguration()
    try checkStructuredAIResultParsing()
    try checkPhraseStore()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
