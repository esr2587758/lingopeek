import Foundation
import LingobarCore
import ApplicationServices

enum AppSettings {
    static let modelKey = "aiModel"
    static let baseURLKey = "aiBaseURL"
    static let hotKeyCodeKey = "Lingobar.hotKey.keyCode"
    static let hotKeyModifiersKey = "Lingobar.hotKey.modifiers"
    static let hotKeyDidChangeNotification = Notification.Name("Lingobar.hotKeyDidChange")

    static let defaultModel = "deepseek-chat"
    static let defaultBaseURL = "https://api.deepseek.com"

    static var model: String {
        let env = firstNonEmpty(
            ProcessInfo.processInfo.environment["AI_MODEL"],
            ProcessInfo.processInfo.environment["DEEPSEEK_MODEL"]
        )
        let stored = UserDefaults.standard.string(forKey: modelKey)
        return firstNonEmpty(env, stored, defaultModel)
    }

    static var baseURLString: String {
        let env = firstNonEmpty(
            ProcessInfo.processInfo.environment["AI_BASE_URL"],
            ProcessInfo.processInfo.environment["DEEPSEEK_BASE_URL"]
        )
        let stored = UserDefaults.standard.string(forKey: baseURLKey)
        return firstNonEmpty(env, stored, defaultBaseURL)
    }

    static var apiToken: String {
        let env = firstNonEmpty(
            ProcessInfo.processInfo.environment["AI_API_TOKEN"],
            ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"]
        )
        return firstNonEmpty(env, LocalTokenStore.readToken())
    }

    static var aiConfiguration: AIProviderConfiguration {
        AIProviderConfiguration(apiToken: apiToken, baseURLString: baseURLString, model: model)
    }

    static var setupGateStatus: SetupGateStatus {
        SetupGateStatus(
            aiAccessConfigured: aiConfiguration.isUsable,
            accessibilityPermissionGranted: isAccessibilityPermissionGranted
        )
    }

    static var hotKey: LingobarHotKey {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: hotKeyCodeKey) != nil,
              defaults.object(forKey: hotKeyModifiersKey) != nil else {
            return .default
        }
        return LingobarHotKey(
            keyCode: UInt32(defaults.integer(forKey: hotKeyCodeKey)),
            carbonModifiers: UInt32(defaults.integer(forKey: hotKeyModifiersKey))
        )
    }

    static func saveHotKey(_ hotKey: LingobarHotKey) {
        let defaults = UserDefaults.standard
        defaults.set(Int(hotKey.keyCode), forKey: hotKeyCodeKey)
        defaults.set(Int(hotKey.carbonModifiers), forKey: hotKeyModifiersKey)
        NotificationCenter.default.post(name: hotKeyDidChangeNotification, object: nil)
    }

    static func resetHotKey() {
        saveHotKey(.default)
    }

    static var isAccessibilityPermissionGranted: Bool {
        AXIsProcessTrusted()
    }

    static func makeAIClient() -> OpenAICompatibleClient? {
        let configuration = aiConfiguration
        guard configuration.isUsable else {
            return nil
        }
        return OpenAICompatibleClient(configuration: configuration)
    }

    private static func firstNonEmpty(_ values: String?...) -> String {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }
}
