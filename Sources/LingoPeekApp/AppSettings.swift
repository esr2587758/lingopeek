import Foundation
import LingobarCore
import ApplicationServices

enum AppSettings {
    static let modelKey = "aiModel"
    static let baseURLKey = "aiBaseURL"
    static let aiProviderKey = "Lingobar.settings.aiProvider"
    static let launchAtLoginKey = "Lingobar.settings.launchAtLogin"
    static let showMenuBarIconKey = "Lingobar.settings.showMenuBarIcon"
    static let appearanceSchemeKey = "Lingobar.settings.appearanceScheme"
    static let triggerOnSelectionKey = "Lingobar.settings.triggerOnSelection"
    static let showSelectionFloatButtonKey = "Lingobar.settings.showSelectionFloatButton"
    static let defaultEnglishActionKey = "Lingobar.settings.defaultEnglishAction"
    static let defaultChineseMixedActionKey = "Lingobar.settings.defaultChineseMixedAction"
    static let actionOrderKey = "Lingobar.settings.actionOrder"
    static let collectionTargetKey = "Lingobar.settings.collectionTarget"
    static let autoReadClipboardKey = "Lingobar.settings.autoReadClipboard"
    static let hotKeyCodeKey = "Lingobar.hotKey.keyCode"
    static let hotKeyModifiersKey = "Lingobar.hotKey.modifiers"
    static let hotKeyDidChangeNotification = Notification.Name("Lingobar.hotKeyDidChange")
    static let settingsDidChangeNotification = Notification.Name("Lingobar.settingsDidChange")

    static let defaultModel = LingobarAIProvider.openAICompatible.defaultModel
    static let defaultBaseURL = LingobarAIProvider.openAICompatible.defaultBaseURLString

    static var aiProvider: LingobarAIProvider {
        let rawValue = UserDefaults.standard.string(forKey: aiProviderKey) ?? ""
        return LingobarAIProvider(rawValue: rawValue) ?? .openAICompatible
    }

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
        if uiTestBypassesSetupGate {
            return SetupGateStatus(
                aiAccessConfigured: aiConfiguration.isUsable,
                accessibilityPermissionGranted: true
            )
        }
        return SetupGateStatus(
            aiAccessConfigured: aiConfiguration.isUsable,
            accessibilityPermissionGranted: isAccessibilityPermissionGranted
        )
    }

    static var uiTestBypassesSetupGate: Bool {
        let environment = ProcessInfo.processInfo.environment
        if firstNonEmpty(environment["LINGOPEEK_UI_TEST_BYPASS_SETUP"]) == "1" {
            return true
        }
        guard isUITestRuntime else {
            return false
        }
        return UserDefaults.standard.bool(forKey: "LINGOPEEK_UI_TEST_BYPASS_SETUP")
    }

    private static var isUITestRuntime: Bool {
        let environment = ProcessInfo.processInfo.environment
        if firstNonEmpty(environment["LINGOPEEK_UI_TEST_MODE"]) == "1" {
            return true
        }
        return Bundle.main.bundleIdentifier?.localizedCaseInsensitiveContains("UITest") == true
    }

    static var uiTestMetricsPath: String {
        firstNonEmpty(
            ProcessInfo.processInfo.environment["LINGOPEEK_UI_TEST_METRICS_PATH"],
            UserDefaults.standard.string(forKey: "LINGOPEEK_UI_TEST_METRICS_PATH")
        )
    }

    static var usesGrammarFixture: Bool {
        firstNonEmpty(ProcessInfo.processInfo.environment["LINGOPEEK_GRAMMAR_FIXTURE"]) == "1"
    }

    static var accessibilityRuntimeIdentityNote: String {
        guard isSwiftPMRuntime else {
            return ""
        }
        let executablePath = Bundle.main.executableURL?.path ?? CommandLine.arguments.first ?? "unknown"
        let bundleID = Bundle.main.bundleIdentifier ?? "无 bundle id"
        return "当前通过 SwiftPM/debug 可执行文件运行。macOS 辅助功能权限可能归属于 Terminal、Codex 或 .build 里的调试程序，不等同于系统设置中的 LingoPeek.app。当前 bundle：\(bundleID)，可执行文件：\(executablePath)"
    }

    private static var isSwiftPMRuntime: Bool {
        let executablePath = Bundle.main.executableURL?.path ?? CommandLine.arguments.first ?? ""
        return executablePath.contains("/.build/") || !Bundle.main.bundleURL.path.hasSuffix(".app")
    }

    static var grammarFixtureID: String {
        firstNonEmpty(ProcessInfo.processInfo.environment["LINGOPEEK_GRAMMAR_FIXTURE_ID"], "mockup")
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

    static var launchAtLogin: Bool {
        bool(forKey: launchAtLoginKey, defaultValue: true)
    }

    static var showMenuBarIcon: Bool {
        bool(forKey: showMenuBarIconKey, defaultValue: true)
    }

    static var appearanceScheme: LingobarAppearanceScheme {
        let rawValue = UserDefaults.standard.string(forKey: appearanceSchemeKey) ?? ""
        return LingobarAppearanceScheme(rawValue: rawValue) ?? .glass
    }

    static var triggerOnSelection: Bool {
        bool(forKey: triggerOnSelectionKey, defaultValue: true)
    }

    static var showSelectionFloatButton: Bool {
        bool(forKey: showSelectionFloatButtonKey, defaultValue: true)
    }

    static var defaultEnglishAction: LanguageAction {
        let action = languageAction(forKey: defaultEnglishActionKey, defaultValue: .translate)
        return LingobarSettingsSnapshot.englishDefaultActions.contains(action) ? action : .translate
    }

    static var defaultChineseMixedAction: LanguageAction {
        let action = languageAction(forKey: defaultChineseMixedActionKey, defaultValue: .rewrite)
        return LingobarSettingsSnapshot.chineseMixedDefaultActions.contains(action) ? action : .rewrite
    }

    static var collectionTarget: LingobarCollectionTarget {
        let rawValue = UserDefaults.standard.string(forKey: collectionTargetKey) ?? ""
        return LingobarCollectionTarget(rawValue: rawValue) ?? .followCurrentPanel
    }

    static var autoReadClipboard: Bool {
        bool(forKey: autoReadClipboardKey, defaultValue: false)
    }

    static var actionOrder: [LanguageAction] {
        let stored = UserDefaults.standard.stringArray(forKey: actionOrderKey) ?? []
        let defaultOrder = LingobarSettingsSnapshot.defaultActionOrder
        var parsed: [LanguageAction] = []
        for rawValue in stored {
            guard let action = LanguageAction(rawValue: rawValue),
                  LanguageAction.selectionActions.contains(action),
                  !parsed.contains(action) else {
                continue
            }
            parsed.append(action)
        }
        return parsed + defaultOrder.filter { !parsed.contains($0) }
    }

    static func makeSettingsSnapshot() -> LingobarSettingsSnapshot {
        LingobarSettingsSnapshot(
            launchAtLogin: launchAtLogin,
            showMenuBarIcon: showMenuBarIcon,
            appearanceScheme: appearanceScheme,
            aiProvider: aiProvider,
            model: model,
            baseURLString: baseURLString,
            apiToken: apiToken,
            accessibilityPermissionGranted: isAccessibilityPermissionGranted,
            triggerOnSelection: triggerOnSelection,
            showSelectionFloatButton: showSelectionFloatButton,
            inputHotKeyDisplay: [hotKey.displayString],
            actionOrder: actionOrder,
            defaultEnglishAction: defaultEnglishAction,
            defaultChineseMixedAction: defaultChineseMixedAction,
            collectionTarget: collectionTarget,
            autoReadClipboard: autoReadClipboard
        )
    }

    static func saveLaunchAtLogin(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: launchAtLoginKey)
        postSettingsDidChange()
    }

    static func saveShowMenuBarIcon(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: showMenuBarIconKey)
        postSettingsDidChange()
    }

    static func saveAppearanceScheme(_ scheme: LingobarAppearanceScheme) {
        UserDefaults.standard.set(scheme.rawValue, forKey: appearanceSchemeKey)
        postSettingsDidChange()
    }

    static func saveAIProvider(_ provider: LingobarAIProvider) {
        UserDefaults.standard.set(provider.rawValue, forKey: aiProviderKey)
        postSettingsDidChange()
    }

    static func saveModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: modelKey)
        postSettingsDidChange()
    }

    static func saveBaseURL(_ baseURL: String) {
        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
        postSettingsDidChange()
    }

    static func saveAPIToken(_ token: String) {
        LocalTokenStore.saveToken(token)
        postSettingsDidChange()
    }

    static func deleteAPIToken() {
        LocalTokenStore.deleteToken()
        postSettingsDidChange()
    }

    static func saveTriggerOnSelection(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: triggerOnSelectionKey)
        postSettingsDidChange()
    }

    static func saveShowSelectionFloatButton(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: showSelectionFloatButtonKey)
        postSettingsDidChange()
    }

    static func saveDefaultEnglishAction(_ action: LanguageAction) {
        UserDefaults.standard.set(action.rawValue, forKey: defaultEnglishActionKey)
        postSettingsDidChange()
    }

    static func saveDefaultChineseMixedAction(_ action: LanguageAction) {
        UserDefaults.standard.set(action.rawValue, forKey: defaultChineseMixedActionKey)
        postSettingsDidChange()
    }

    static func saveActionOrder(_ actions: [LanguageAction]) {
        UserDefaults.standard.set(actions.map(\.rawValue), forKey: actionOrderKey)
        postSettingsDidChange()
    }

    static func saveCollectionTarget(_ target: LingobarCollectionTarget) {
        UserDefaults.standard.set(target.rawValue, forKey: collectionTargetKey)
        postSettingsDidChange()
    }

    static func saveAutoReadClipboard(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: autoReadClipboardKey)
        postSettingsDidChange()
    }

    static func resetForUITesting() {
        let keys = [
            aiProviderKey,
            launchAtLoginKey,
            showMenuBarIconKey,
            appearanceSchemeKey,
            triggerOnSelectionKey,
            showSelectionFloatButtonKey,
            defaultEnglishActionKey,
            defaultChineseMixedActionKey,
            actionOrderKey,
            collectionTargetKey,
            autoReadClipboardKey,
            modelKey,
            baseURLKey,
            hotKeyCodeKey,
            hotKeyModifiersKey
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        LocalTokenStore.deleteToken()
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

    private static func bool(forKey key: String, defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    private static func languageAction(forKey key: String, defaultValue: LanguageAction) -> LanguageAction {
        let rawValue = UserDefaults.standard.string(forKey: key) ?? ""
        return LanguageAction(rawValue: rawValue) ?? defaultValue
    }

    private static func postSettingsDidChange() {
        NotificationCenter.default.post(name: settingsDidChangeNotification, object: nil)
    }
}
