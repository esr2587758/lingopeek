import Foundation
import LingobarCore
import ApplicationServices
import Security

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
    static let defaultEnglishActionIDKey = "Lingobar.settings.defaultEnglishActionID"
    static let defaultChineseMixedActionIDKey = "Lingobar.settings.defaultChineseMixedActionID"
    static let actionOrderKey = "Lingobar.settings.actionOrder"
    static let actionOrderIDsKey = "Lingobar.settings.actionOrderIDs"
    static let customPromptActionsKey = "Lingobar.settings.customPromptActions"
    static let collectionTargetKey = "Lingobar.settings.collectionTarget"
    static let autoReadClipboardKey = "Lingobar.settings.autoReadClipboard"
    static let hotKeyCodeKey = "Lingobar.hotKey.keyCode"
    static let hotKeyModifiersKey = "Lingobar.hotKey.modifiers"
    static let inputHotKeyCodeKey = "Lingobar.inputHotKey.keyCode"
    static let inputHotKeyModifiersKey = "Lingobar.inputHotKey.modifiers"
    static let selectionHotKeyCodeKey = "Lingobar.selectionHotKey.keyCode"
    static let selectionHotKeyModifiersKey = "Lingobar.selectionHotKey.modifiers"
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
                aiAccessConfigured: true,
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
        let executablePath = Bundle.main.executableURL?.path ?? CommandLine.arguments.first ?? "unknown"
        let bundleID = Bundle.main.bundleIdentifier ?? "无 bundle id"
        guard isSwiftPMRuntime else {
            guard isUnstableLocalCodeSignature else {
                return ""
            }
            return "当前运行的是本地开发版 .app（未使用稳定 Developer ID/Team 签名）。macOS 辅助功能权限会绑定到当前签名身份；如果你重建或替换过 LingoPeek.app，请在系统设置中删除旧的 LingoPeek 条目，退出并重新打开当前 app 后再添加授权。当前 bundle：\(bundleID)，可执行文件：\(executablePath)"
        }
        return "当前通过 SwiftPM/debug 可执行文件运行。macOS 辅助功能权限可能归属于 Terminal、Codex 或 .build 里的调试程序，不等同于系统设置中的 LingoPeek.app。当前 bundle：\(bundleID)，可执行文件：\(executablePath)"
    }

    private static var isUnstableLocalCodeSignature: Bool {
        guard let signingTeamIdentifier else {
            return true
        }
        return signingTeamIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static var signingTeamIdentifier: String? {
        var code: SecCode?
        guard SecCodeCopySelf(SecCSFlags(), &code) == errSecSuccess, let code else {
            return nil
        }

        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode else {
            return nil
        }

        var signingInfo: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &signingInfo) == errSecSuccess,
              let signingInfo = signingInfo as? [String: Any] else {
            return nil
        }

        return signingInfo[kSecCodeInfoTeamIdentifier as String] as? String
    }

    private static var isSwiftPMRuntime: Bool {
        let executablePath = Bundle.main.executableURL?.path ?? CommandLine.arguments.first ?? ""
        return executablePath.contains("/.build/") || !Bundle.main.bundleURL.path.hasSuffix(".app")
    }

    static var grammarFixtureID: String {
        firstNonEmpty(ProcessInfo.processInfo.environment["LINGOPEEK_GRAMMAR_FIXTURE_ID"], "mockup")
    }

    static var hotKey: LingobarHotKey {
        inputHotKey
    }

    static var inputHotKey: LingobarHotKey {
        let defaults = UserDefaults.standard
        let codeKey = defaults.object(forKey: inputHotKeyCodeKey) != nil ? inputHotKeyCodeKey : hotKeyCodeKey
        let modifiersKey = defaults.object(forKey: inputHotKeyModifiersKey) != nil ? inputHotKeyModifiersKey : hotKeyModifiersKey
        guard defaults.object(forKey: codeKey) != nil,
              defaults.object(forKey: modifiersKey) != nil else {
            return .default
        }
        return LingobarHotKey(
            keyCode: UInt32(defaults.integer(forKey: codeKey)),
            carbonModifiers: UInt32(defaults.integer(forKey: modifiersKey))
        )
    }

    static var selectionHotKey: LingobarHotKey {
        hotKey(forCodeKey: selectionHotKeyCodeKey, modifiersKey: selectionHotKeyModifiersKey, defaultValue: .defaultSelection)
    }

    static func saveHotKey(_ hotKey: LingobarHotKey) {
        saveInputHotKey(hotKey)
    }

    static func saveInputHotKey(_ hotKey: LingobarHotKey) {
        let defaults = UserDefaults.standard
        defaults.set(Int(hotKey.keyCode), forKey: inputHotKeyCodeKey)
        defaults.set(Int(hotKey.carbonModifiers), forKey: inputHotKeyModifiersKey)
        NotificationCenter.default.post(name: hotKeyDidChangeNotification, object: nil)
    }

    static func saveSelectionHotKey(_ hotKey: LingobarHotKey) {
        let defaults = UserDefaults.standard
        defaults.set(Int(hotKey.keyCode), forKey: selectionHotKeyCodeKey)
        defaults.set(Int(hotKey.carbonModifiers), forKey: selectionHotKeyModifiersKey)
        NotificationCenter.default.post(name: hotKeyDidChangeNotification, object: nil)
    }

    static func resetHotKey() {
        resetInputHotKey()
    }

    static func resetInputHotKey() {
        saveInputHotKey(.default)
    }

    static func resetSelectionHotKey() {
        saveSelectionHotKey(.defaultSelection)
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

    static var defaultEnglishActionID: String {
        validDefaultActionID(
            forKey: defaultEnglishActionIDKey,
            legacyKey: defaultEnglishActionKey,
            fallback: defaultEnglishAction.actionID
        )
    }

    static var defaultChineseMixedActionID: String {
        validDefaultActionID(
            forKey: defaultChineseMixedActionIDKey,
            legacyKey: defaultChineseMixedActionKey,
            fallback: defaultChineseMixedAction.actionID
        )
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

    static var customPromptActions: [CustomPromptAction] {
        guard let data = UserDefaults.standard.data(forKey: customPromptActionsKey),
              let actions = try? JSONDecoder().decode([CustomPromptAction].self, from: data) else {
            return []
        }
        return normalizedCustomPromptActions(actions)
    }

    static var actionOrderIDs: [String] {
        let stored = UserDefaults.standard.stringArray(forKey: actionOrderIDsKey)
        let fallback = LingobarActionCatalog.defaultOrderIDs(from: actionOrder)
        let base = stored?.isEmpty == false ? stored! : fallback
        return LingobarActionCatalog.descriptors(customPromptActions: customPromptActions, orderIDs: base).map(\.id)
    }

    static var actionDescriptors: [LingobarActionDescriptor] {
        LingobarActionCatalog.descriptors(
            customPromptActions: customPromptActions,
            orderIDs: actionOrderIDs
        )
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
            inputHotKeyDisplay: [inputHotKey.displayString],
            selectionHotKeyDisplay: [selectionHotKey.displayString],
            actionOrder: actionOrder,
            actionOrderIDs: actionOrderIDs,
            customPromptActions: customPromptActions,
            defaultEnglishAction: defaultEnglishAction,
            defaultChineseMixedAction: defaultChineseMixedAction,
            defaultEnglishActionID: defaultEnglishActionID,
            defaultChineseMixedActionID: defaultChineseMixedActionID,
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
        UserDefaults.standard.set(action.actionID, forKey: defaultEnglishActionIDKey)
        postSettingsDidChange()
    }

    static func saveDefaultChineseMixedAction(_ action: LanguageAction) {
        UserDefaults.standard.set(action.rawValue, forKey: defaultChineseMixedActionKey)
        UserDefaults.standard.set(action.actionID, forKey: defaultChineseMixedActionIDKey)
        postSettingsDidChange()
    }

    static func saveDefaultEnglishActionID(_ actionID: String) {
        UserDefaults.standard.set(actionID, forKey: defaultEnglishActionIDKey)
        if let builtIn = LanguageAction(rawValue: actionID) {
            UserDefaults.standard.set(builtIn.rawValue, forKey: defaultEnglishActionKey)
        }
        postSettingsDidChange()
    }

    static func saveDefaultChineseMixedActionID(_ actionID: String) {
        UserDefaults.standard.set(actionID, forKey: defaultChineseMixedActionIDKey)
        if let builtIn = LanguageAction(rawValue: actionID) {
            UserDefaults.standard.set(builtIn.rawValue, forKey: defaultChineseMixedActionKey)
        }
        postSettingsDidChange()
    }

    static func saveActionOrder(_ actions: [LanguageAction]) {
        UserDefaults.standard.set(actions.map(\.rawValue), forKey: actionOrderKey)
        UserDefaults.standard.set(actions.map(\.actionID), forKey: actionOrderIDsKey)
        postSettingsDidChange()
    }

    static func saveActionOrderIDs(_ actionIDs: [String]) {
        UserDefaults.standard.set(actionIDs, forKey: actionOrderIDsKey)
        postSettingsDidChange()
    }

    static func saveCustomPromptAction(_ action: CustomPromptAction) -> Bool {
        var actions = customPromptActions
        let normalized = CustomPromptAction(id: action.id, title: action.title, promptTemplate: action.promptTemplate, createdAt: action.createdAt, updatedAt: Date())
        guard isValidCustomPromptAction(normalized, existing: actions) else {
            return false
        }
        if let index = actions.firstIndex(where: { $0.id == normalized.id }) {
            actions[index] = normalized
        } else {
            actions.append(normalized)
        }
        saveCustomPromptActions(actions)
        saveActionOrderIDs(LingobarActionCatalog.descriptors(customPromptActions: actions, orderIDs: actionOrderIDs + [normalized.actionID]).map(\.id))
        return true
    }

    static func deleteCustomPromptAction(id: UUID) {
        var actions = customPromptActions
        guard let deleted = actions.first(where: { $0.id == id }) else {
            return
        }
        actions.removeAll { $0.id == id }
        let nextDefault = LingobarActionCatalog.nextEligibleDefaultActionID(
            after: deleted.actionID,
            orderIDs: actionOrderIDs,
            customPromptActions: actions
        )
        saveCustomPromptActions(actions)
        saveActionOrderIDs(actionOrderIDs.filter { $0 != deleted.actionID })
        if defaultEnglishActionID == deleted.actionID {
            saveDefaultEnglishActionID(nextDefault)
        }
        if defaultChineseMixedActionID == deleted.actionID {
            saveDefaultChineseMixedActionID(nextDefault)
        }
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
            defaultEnglishActionIDKey,
            defaultChineseMixedActionIDKey,
            actionOrderKey,
            actionOrderIDsKey,
            customPromptActionsKey,
            collectionTargetKey,
            autoReadClipboardKey,
            modelKey,
            baseURLKey,
            hotKeyCodeKey,
            hotKeyModifiersKey,
            inputHotKeyCodeKey,
            inputHotKeyModifiersKey,
            selectionHotKeyCodeKey,
            selectionHotKeyModifiersKey
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

    private static func hotKey(forCodeKey codeKey: String, modifiersKey: String, defaultValue: LingobarHotKey) -> LingobarHotKey {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: codeKey) != nil,
              defaults.object(forKey: modifiersKey) != nil else {
            return defaultValue
        }
        return LingobarHotKey(
            keyCode: UInt32(defaults.integer(forKey: codeKey)),
            carbonModifiers: UInt32(defaults.integer(forKey: modifiersKey))
        )
    }

    private static func validDefaultActionID(forKey key: String, legacyKey: String, fallback: String) -> String {
        let stored = UserDefaults.standard.string(forKey: key)
            ?? UserDefaults.standard.string(forKey: legacyKey)
            ?? fallback
        if actionDescriptors.contains(where: { $0.id == stored && $0.isResultProducing }) {
            return stored
        }
        return fallback
    }

    private static func saveCustomPromptActions(_ actions: [CustomPromptAction]) {
        let normalized = normalizedCustomPromptActions(actions)
        if let data = try? JSONEncoder().encode(normalized) {
            UserDefaults.standard.set(data, forKey: customPromptActionsKey)
        }
    }

    private static func normalizedCustomPromptActions(_ actions: [CustomPromptAction]) -> [CustomPromptAction] {
        var seenTitles: Set<String> = []
        return actions.compactMap { action in
            let title = action.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let prompt = action.promptTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            let titleKey = title.lowercased()
            guard !title.isEmpty,
                  !prompt.isEmpty,
                  LanguageAction.selectionActions.allSatisfy({ $0.title.lowercased() != titleKey }),
                  !seenTitles.contains(titleKey) else {
                return nil
            }
            seenTitles.insert(titleKey)
            return CustomPromptAction(
                id: action.id,
                title: title,
                promptTemplate: prompt,
                createdAt: action.createdAt,
                updatedAt: action.updatedAt
            )
        }
    }

    private static func isValidCustomPromptAction(_ action: CustomPromptAction, existing: [CustomPromptAction]) -> Bool {
        let title = action.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let prompt = action.promptTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              !prompt.isEmpty,
              LanguageAction.selectionActions.allSatisfy({ $0.title.lowercased() != title }) else {
            return false
        }
        return existing.allSatisfy { $0.id == action.id || $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != title }
    }

    private static func postSettingsDidChange() {
        NotificationCenter.default.post(name: settingsDidChangeNotification, object: nil)
    }
}
