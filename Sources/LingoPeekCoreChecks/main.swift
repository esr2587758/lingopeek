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

    let translate = engine.result(for: .translate, text: "any sentence can become a small object")
    try check(translate.title == "自然翻译", "translate title should match")
    try check(translate.summary.contains("学习对象"), "translate summary should mention 学习对象")
    try check(translate.chips.contains("learning object"), "translate chips should include learning object")

    let ask = engine.result(for: .ask, text: "选中即解析，输入即生成")
    try check(ask.title == "表达生成", "ask title should match")
    try check(ask.summary.contains("selection-first"), "ask summary should stay product-focused")
    try check(ask.shortcut == "Return", "ask shortcut should be Return")
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
    try checkPhraseStore()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
