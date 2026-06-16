import Foundation

public enum LingobarMode: String, CaseIterable, Sendable {
    case setup
    case selection
    case input
}

public enum LanguageAction: String, CaseIterable, Identifiable, Sendable {
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
        switch self {
        case .copy: "⌘C"
        case .translate: "⌘1"
        case .grammar: "⌘2"
        case .rewrite: "⌘3"
        case .examples: "⌘4"
        case .collect: "⌘S"
        case .pronounce: "⌘P"
        }
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
