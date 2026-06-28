import Foundation

public enum LingobarMode: String, CaseIterable, Sendable {
    case setup
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

    public var title: String {
        switch self {
        case .copy: "复制"
        case .translate: "翻译"
        case .grammar: "语法"
        case .rewrite: "改写"
        case .examples: "例句"
        case .collect: "收藏"
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
        case .collect: "star"
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

private func containsChinese(in text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
        (0x4E00...0x9FFF).contains(Int(scalar.value))
    }
}
