import Foundation

public enum LingobarMode: String, CaseIterable, Sendable {
    case setup
    case launcher
    case selection
    case input
}

public enum LanguageAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case copy
    case translate
    case grammar
    case rewrite
    case examples
    case collect
    case pronounce

    public static let selectionActions: [LanguageAction] = [
        .translate,
        .grammar,
        .rewrite,
        .examples,
        .collect,
        .pronounce
    ]

    private static let selectionShortcutKeySlots = ["1", "2", "3", "4", "5", "p"]

    public static func defaultSelectionAction(for text: String) -> LanguageAction {
        containsChinese(in: text) ? .rewrite : .translate
    }

    public func isAvailable(for text: String) -> Bool {
        switch self {
        case .grammar:
            !containsChinese(in: text)
        default:
            true
        }
    }

    public var id: String { rawValue }

    public var actionID: String { rawValue }

    public var isResultProducing: Bool {
        switch self {
        case .translate, .grammar, .rewrite, .examples, .pronounce:
            true
        case .copy, .collect:
            false
        }
    }

    public var title: String {
        switch self {
        case .copy: "复制"
        case .translate: "翻译"
        case .grammar: "语法"
        case .rewrite: "改写"
        case .examples: "例句"
        case .collect: "保存"
        case .pronounce: "发音"
        }
    }

    public var symbol: String {
        switch self {
        case .copy: "doc.on.doc"
        case .translate: "character.book.closed"
        case .grammar: "point.3.connected.trianglepath.dotted"
        case .rewrite: "pencil"
        case .examples: "quote.opening"
        case .collect: "bookmark"
        case .pronounce: "speaker.wave.2"
        }
    }

    public var shortcut: String {
        Self.shortcut(for: self)
    }

    public var keyEquivalent: String {
        Self.keyEquivalent(for: self)
    }

    public static func shortcut(
        for action: LanguageAction,
        in actionOrder: [LanguageAction] = selectionActions
    ) -> String {
        let keyEquivalent = keyEquivalent(for: action, in: actionOrder)
        return keyEquivalent.isEmpty ? "" : "⌘\(keyEquivalent.uppercased())"
    }

    public static func keyEquivalent(
        for action: LanguageAction,
        in actionOrder: [LanguageAction] = selectionActions
    ) -> String {
        if action == .copy {
            return "c"
        }

        let normalizedOrder = normalizedSelectionActionOrder(actionOrder)
        guard let index = normalizedOrder.firstIndex(of: action),
              selectionShortcutKeySlots.indices.contains(index) else {
            return ""
        }
        return selectionShortcutKeySlots[index]
    }

    public static func matchingKeyboardShortcut(
        keyEquivalent: String,
        command: Bool,
        option: Bool = false,
        control: Bool = false,
        shift: Bool = false,
        actionOrder: [LanguageAction] = selectionActions
    ) -> LanguageAction? {
        guard command, !option, !control, !shift else {
            return nil
        }

        let normalizedKey = keyEquivalent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalizedKey == Self.keyEquivalent(for: .copy) {
            return .copy
        }

        guard let slotIndex = selectionShortcutKeySlots.firstIndex(of: normalizedKey) else {
            return nil
        }

        let normalizedOrder = normalizedSelectionActionOrder(actionOrder)
        guard normalizedOrder.indices.contains(slotIndex) else {
            return nil
        }
        return normalizedOrder[slotIndex]
    }

    public static func normalizedSelectionActionOrder(_ actionOrder: [LanguageAction]) -> [LanguageAction] {
        var normalized: [LanguageAction] = []
        for action in actionOrder where selectionActions.contains(action) && !normalized.contains(action) {
            normalized.append(action)
        }
        return normalized + selectionActions.filter { !normalized.contains($0) }
    }

    public var moreActionTitle: String {
        switch self {
        case .translate: "解释更多"
        case .grammar: "继续拆解"
        case .rewrite: "更多版本"
        case .examples: "更多例句"
        case .pronounce: "慢速播放"
        case .copy, .collect: ""
        }
    }
}

public struct CustomPromptAction: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var promptTemplate: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        promptTemplate: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.promptTemplate = promptTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    public var actionID: String {
        "custom:\(id.uuidString)"
    }

    public func userPrompt(for text: String) -> String {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if promptTemplate.contains("{text}") {
            return promptTemplate.replacingOccurrences(of: "{text}", with: source)
        }
        return """
        \(promptTemplate)

        Text:
        \(source)
        """
    }
}

public struct LingobarActionDescriptor: Identifiable, Equatable, Sendable {
    public var id: String
    public var builtInAction: LanguageAction?
    public var customPromptAction: CustomPromptAction?

    public init(builtInAction: LanguageAction) {
        self.id = builtInAction.actionID
        self.builtInAction = builtInAction
        self.customPromptAction = nil
    }

    public init(customPromptAction: CustomPromptAction) {
        self.id = customPromptAction.actionID
        self.builtInAction = nil
        self.customPromptAction = customPromptAction
    }

    public var title: String {
        builtInAction?.title ?? customPromptAction?.title ?? "自定义"
    }

    public var symbol: String {
        builtInAction?.symbol ?? "sparkles"
    }

    public var moreActionTitle: String {
        builtInAction?.moreActionTitle ?? "继续处理"
    }

    public var isBuiltIn: Bool {
        builtInAction != nil
    }

    public var isCustomPrompt: Bool {
        customPromptAction != nil
    }

    public var isResultProducing: Bool {
        builtInAction?.isResultProducing ?? true
    }

    public func isAvailable(for text: String) -> Bool {
        guard isResultProducing else {
            return true
        }
        if let builtInAction {
            return builtInAction.isAvailable(for: text)
        }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public enum LingobarActionCatalog {
    private static let shortcutKeySlots = ["1", "2", "3", "4", "5", "p"]

    public static func descriptors(
        customPromptActions: [CustomPromptAction],
        orderIDs: [String]
    ) -> [LingobarActionDescriptor] {
        let builtIns = LanguageAction.selectionActions.map(LingobarActionDescriptor.init)
        let custom = customPromptActions.map(LingobarActionDescriptor.init)
        let all = builtIns + custom
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var normalized: [LingobarActionDescriptor] = []

        for id in orderIDs {
            guard let descriptor = byID[id], !normalized.contains(where: { $0.id == id }) else {
                continue
            }
            normalized.append(descriptor)
        }

        for descriptor in all where !normalized.contains(where: { $0.id == descriptor.id }) {
            normalized.append(descriptor)
        }

        return normalized
    }

    public static func defaultOrderIDs(from actions: [LanguageAction]) -> [String] {
        actions.map(\.actionID)
    }

    public static func shortcut(
        for descriptor: LingobarActionDescriptor,
        in descriptors: [LingobarActionDescriptor]
    ) -> String {
        let keyEquivalent = keyEquivalent(for: descriptor, in: descriptors)
        return keyEquivalent.isEmpty ? "" : "⌘\(keyEquivalent.uppercased())"
    }

    public static func keyEquivalent(
        for descriptor: LingobarActionDescriptor,
        in descriptors: [LingobarActionDescriptor]
    ) -> String {
        guard let index = descriptors.firstIndex(where: { $0.id == descriptor.id }),
              shortcutKeySlots.indices.contains(index) else {
            return ""
        }
        return shortcutKeySlots[index]
    }

    public static func matchingKeyboardShortcut(
        keyEquivalent: String,
        command: Bool,
        option: Bool = false,
        control: Bool = false,
        shift: Bool = false,
        descriptors: [LingobarActionDescriptor]
    ) -> LingobarActionDescriptor? {
        guard command, !option, !control, !shift else {
            return nil
        }

        let normalizedKey = keyEquivalent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let slotIndex = shortcutKeySlots.firstIndex(of: normalizedKey),
              descriptors.indices.contains(slotIndex) else {
            return nil
        }
        return descriptors[slotIndex]
    }

    public static func nextEligibleDefaultActionID(
        after removedID: String,
        orderIDs: [String],
        customPromptActions: [CustomPromptAction]
    ) -> String {
        let filteredOrder = orderIDs.filter { $0 != removedID }
        let descriptors = descriptors(customPromptActions: customPromptActions, orderIDs: filteredOrder)
        guard !descriptors.isEmpty else {
            return LanguageAction.defaultSelectionAction(for: "").actionID
        }

        if let removedIndex = orderIDs.firstIndex(of: removedID) {
            let rotatedIDs = Array(orderIDs[(removedIndex + 1)...] + orderIDs[..<removedIndex])
            for id in rotatedIDs where id != removedID {
                if let descriptor = descriptors.first(where: { $0.id == id }), descriptor.isResultProducing {
                    return descriptor.id
                }
            }
        }

        return descriptors.first(where: \.isResultProducing)?.id ?? LanguageAction.translate.actionID
    }
}

private func containsChinese(in text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
        (0x4E00...0x9FFF).contains(Int(scalar.value))
    }
}
