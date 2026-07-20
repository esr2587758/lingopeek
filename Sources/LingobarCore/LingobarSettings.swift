import Foundation

public enum LingobarSettingsSectionID: String, CaseIterable, Identifiable, Codable, Sendable {
    case general
    case ai
    case permissions
    case trigger
    case actions
    case collection
    case about

    public var id: String { rawValue }
}

public struct LingobarSettingsSectionDescriptor: Equatable, Identifiable, Sendable {
    public var id: LingobarSettingsSectionID
    public var title: String
    public var subtitle: String
    public var symbolName: String
    public var requiresSetupGate: Bool

    public init(
        id: LingobarSettingsSectionID,
        title: String,
        subtitle: String,
        symbolName: String,
        requiresSetupGate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.requiresSetupGate = requiresSetupGate
    }

    public static let all: [LingobarSettingsSectionDescriptor] = [
        .init(id: .general, title: "通用", subtitle: "启动与外观", symbolName: "gearshape"),
        .init(id: .ai, title: "AI 服务", subtitle: "模型接入", symbolName: "bolt.fill", requiresSetupGate: true),
        .init(id: .permissions, title: "权限", subtitle: "辅助功能", symbolName: "shield.fill", requiresSetupGate: true),
        .init(id: .trigger, title: "划词与唤起", subtitle: "如何呼出", symbolName: "cursorarrow.click"),
        .init(id: .actions, title: "语言动作", subtitle: "顺序与默认", symbolName: "slider.horizontal.3"),
        .init(id: .collection, title: "收藏", subtitle: "收藏行为", symbolName: "star.fill"),
        .init(id: .about, title: "关于", subtitle: "版本信息", symbolName: "info.circle")
    ]
}

public struct LingobarSettingsSetupGate: Equatable, Sendable {
    public var status: SetupGateStatus

    public init(status: SetupGateStatus) {
        self.status = status
    }

    public var isReady: Bool {
        status.requiredAction == .useLingobar
    }

    public var footerTitle: String {
        isReady ? "" : "需完成必填项"
    }

    public var sectionIDsNeedingAttention: [LingobarSettingsSectionID] {
        var ids: [LingobarSettingsSectionID] = []
        if !status.aiAccessConfigured {
            ids.append(.ai)
        }
        if !status.accessibilityPermissionGranted {
            ids.append(.permissions)
        }
        return ids
    }
}

public enum LingobarAIProvider: String, CaseIterable, Identifiable, Codable, Sendable {
    case claudeAnthropic
    case openAI
    case openAICompatible

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .claudeAnthropic: "Claude (Anthropic)"
        case .openAI: "OpenAI"
        case .openAICompatible: "自定义 / 兼容 OpenAI"
        }
    }

    public var modelOptions: [String] {
        switch self {
        case .claudeAnthropic:
            ["claude-opus-4-8", "claude-sonnet-4-6", "claude-haiku-4-5"]
        case .openAI:
            ["gpt-4o", "gpt-4o-mini"]
        case .openAICompatible:
            ["deepseek-chat", "deepseek-reasoner"]
        }
    }

    public var defaultModel: String {
        modelOptions[0]
    }

    public var defaultBaseURLString: String {
        switch self {
        case .claudeAnthropic: "https://api.anthropic.com/v1"
        case .openAI: "https://api.openai.com/v1"
        case .openAICompatible: "https://api.deepseek.com"
        }
    }

    public var showsBaseURLField: Bool {
        self == .openAICompatible
    }
}

public enum LingobarCollectionTarget: String, CaseIterable, Identifiable, Codable, Sendable {
    case followCurrentPanel
    case originalSelection

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .followCurrentPanel: "跟随当前面板"
        case .originalSelection: "总是收原文"
        }
    }

    public var description: String {
        switch self {
        case .followCurrentPanel:
            "翻译收关键表达、改写收主句、例句收首条、语法收句型"
        case .originalSelection:
            "始终收藏选中的原始文本"
        }
    }
}

public enum LingobarAppearanceScheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case glass
    case tool
    case reader
    case brand

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .glass: "Tahoe 玻璃"
        case .tool: "克制工具"
        case .reader: "温暖阅读"
        case .brand: "品牌珊瑚"
        }
    }

    public var subtitle: String {
        switch self {
        case .glass: "系统浅玻璃 · 系统蓝"
        case .tool: "深色 · 键盘优先"
        case .reader: "暖色 · 衬线阅读"
        case .brand: "品牌色调"
        }
    }
}

public struct LingobarSettingsSnapshot: Equatable, Sendable {
    public var launchAtLogin: Bool
    public var showMenuBarIcon: Bool
    public var appearanceScheme: LingobarAppearanceScheme
    public var aiProvider: LingobarAIProvider
    public var model: String
    public var baseURLString: String
    public var apiToken: String
    public var accessibilityPermissionGranted: Bool
    public var triggerOnSelection: Bool
    public var showSelectionFloatButton: Bool
    public var inputHotKeyDisplay: [String]
    public var selectionHotKeyDisplay: [String]
    public var actionOrder: [LanguageAction]
    public var actionOrderIDs: [String]
    public var customPromptActions: [CustomPromptAction]
    public var defaultEnglishAction: LanguageAction
    public var defaultChineseMixedAction: LanguageAction
    public var defaultEnglishActionID: String
    public var defaultChineseMixedActionID: String
    public var collectionTarget: LingobarCollectionTarget
    public var autoReadClipboard: Bool

    public static let defaultActionOrder: [LanguageAction] = [
        .grammar,
        .translate,
        .rewrite,
        .examples,
        .collect,
        .pronounce
    ]

    public init(
        launchAtLogin: Bool = true,
        showMenuBarIcon: Bool = true,
        appearanceScheme: LingobarAppearanceScheme = .glass,
        aiProvider: LingobarAIProvider = .openAICompatible,
        model: String = LingobarAIProvider.openAICompatible.defaultModel,
        baseURLString: String = LingobarAIProvider.openAICompatible.defaultBaseURLString,
        apiToken: String = "",
        accessibilityPermissionGranted: Bool = false,
        triggerOnSelection: Bool = true,
        showSelectionFloatButton: Bool = true,
        inputHotKeyDisplay: [String] = ["⌥", "Space"],
        selectionHotKeyDisplay: [String] = ["⌥", "⌘", "S"],
        actionOrder: [LanguageAction] = LingobarSettingsSnapshot.defaultActionOrder,
        actionOrderIDs: [String]? = nil,
        customPromptActions: [CustomPromptAction] = [],
        defaultEnglishAction: LanguageAction = .translate,
        defaultChineseMixedAction: LanguageAction = .rewrite,
        defaultEnglishActionID: String? = nil,
        defaultChineseMixedActionID: String? = nil,
        collectionTarget: LingobarCollectionTarget = .followCurrentPanel,
        autoReadClipboard: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.appearanceScheme = appearanceScheme
        self.aiProvider = aiProvider
        self.model = model
        self.baseURLString = baseURLString
        self.apiToken = apiToken
        self.accessibilityPermissionGranted = accessibilityPermissionGranted
        self.triggerOnSelection = triggerOnSelection
        self.showSelectionFloatButton = showSelectionFloatButton
        self.inputHotKeyDisplay = inputHotKeyDisplay
        self.selectionHotKeyDisplay = selectionHotKeyDisplay
        self.actionOrder = actionOrder
        self.actionOrderIDs = actionOrderIDs ?? LingobarActionCatalog.defaultOrderIDs(from: actionOrder)
        self.customPromptActions = customPromptActions
        self.defaultEnglishAction = defaultEnglishAction
        self.defaultChineseMixedAction = defaultChineseMixedAction
        self.defaultEnglishActionID = defaultEnglishActionID ?? defaultEnglishAction.actionID
        self.defaultChineseMixedActionID = defaultChineseMixedActionID ?? defaultChineseMixedAction.actionID
        self.collectionTarget = collectionTarget
        self.autoReadClipboard = autoReadClipboard
    }

    public static let defaultValue = LingobarSettingsSnapshot()

    public var setupGateStatus: SetupGateStatus {
        SetupGateStatus(
            aiAccessConfigured: AIProviderConfiguration(
                apiToken: apiToken,
                baseURLString: baseURLString,
                model: model
            ).isUsable,
            accessibilityPermissionGranted: accessibilityPermissionGranted
        )
    }

    public var settingsSetupGate: LingobarSettingsSetupGate {
        LingobarSettingsSetupGate(status: setupGateStatus)
    }

    public mutating func selectAIProvider(_ provider: LingobarAIProvider) {
        aiProvider = provider
        model = provider.defaultModel
        baseURLString = provider.defaultBaseURLString
    }

    public mutating func moveAction(_ action: LanguageAction, before target: LanguageAction) {
        guard action != target,
              let fromIndex = actionOrder.firstIndex(of: action),
              actionOrder.contains(target) else {
            return
        }

        let moving = actionOrder.remove(at: fromIndex)
        let targetIndex = actionOrder.firstIndex(of: target) ?? actionOrder.endIndex
        actionOrder.insert(moving, at: targetIndex)
    }

    public var actionDescriptors: [LingobarActionDescriptor] {
        LingobarActionCatalog.descriptors(
            customPromptActions: customPromptActions,
            orderIDs: actionOrderIDs
        )
    }

    public var resultProducingActionDescriptors: [LingobarActionDescriptor] {
        actionDescriptors.filter(\.isResultProducing)
    }

    @discardableResult
    public mutating func selectDefaultEnglishAction(_ action: LanguageAction) -> Bool {
        guard Self.englishDefaultActions.contains(action) else {
            return false
        }
        defaultEnglishAction = action
        defaultEnglishActionID = action.actionID
        return true
    }

    @discardableResult
    public mutating func selectDefaultChineseMixedAction(_ action: LanguageAction) -> Bool {
        guard Self.chineseMixedDefaultActions.contains(action) else {
            return false
        }
        defaultChineseMixedAction = action
        defaultChineseMixedActionID = action.actionID
        return true
    }

    @discardableResult
    public mutating func selectDefaultEnglishActionID(_ actionID: String) -> Bool {
        guard resultProducingActionDescriptors.contains(where: { $0.id == actionID }) else {
            return false
        }
        defaultEnglishActionID = actionID
        if let builtIn = LanguageAction(rawValue: actionID) {
            defaultEnglishAction = builtIn
        }
        return true
    }

    @discardableResult
    public mutating func selectDefaultChineseMixedActionID(_ actionID: String) -> Bool {
        guard resultProducingActionDescriptors.contains(where: { $0.id == actionID }) else {
            return false
        }
        defaultChineseMixedActionID = actionID
        if let builtIn = LanguageAction(rawValue: actionID) {
            defaultChineseMixedAction = builtIn
        }
        return true
    }

    public static let englishDefaultActions: [LanguageAction] = [
        .translate,
        .grammar,
        .rewrite,
        .examples
    ]

    public static let chineseMixedDefaultActions: [LanguageAction] = [
        .rewrite,
        .translate
    ]
}
