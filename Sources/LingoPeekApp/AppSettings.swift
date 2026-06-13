import Foundation
import LingobarCore

enum AppSettings {
    static let apiKeyKey = "deepseekAPIKey"
    static let modelKey = "deepseekModel"
    static let baseURLKey = "deepseekBaseURL"

    static let defaultModel = "deepseek-v4-flash"
    static let defaultBaseURL = "https://api.deepseek.com"

    static var model: String {
        let env = ProcessInfo.processInfo.environment["DEEPSEEK_MODEL"]
        let stored = UserDefaults.standard.string(forKey: modelKey)
        return firstNonEmpty(env, stored, defaultModel)
    }

    static var baseURLString: String {
        let env = ProcessInfo.processInfo.environment["DEEPSEEK_BASE_URL"]
        let stored = UserDefaults.standard.string(forKey: baseURLKey)
        return firstNonEmpty(env, stored, defaultBaseURL)
    }

    static var apiKey: String {
        let env = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"]
        let stored = UserDefaults.standard.string(forKey: apiKeyKey)
        return firstNonEmpty(env, stored, "")
    }

    static func makeDeepSeekClient() -> DeepSeekClient? {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, let baseURL = URL(string: baseURLString) else {
            return nil
        }
        return DeepSeekClient(baseURL: baseURL, apiKey: key, model: model)
    }

    private static func firstNonEmpty(_ values: String?...) -> String {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }
}
