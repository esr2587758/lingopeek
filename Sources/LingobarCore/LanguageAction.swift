import Foundation

public enum LingobarMode: String, CaseIterable, Sendable {
    case selection
    case input
}

public enum LanguageAction: String, CaseIterable, Identifiable, Sendable {
    case copy
    case translate
    case parse
    case save
    case expand
    case examples
    case pronounce
    case ask

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .copy: "复制"
        case .translate: "翻译"
        case .parse: "拆解"
        case .save: "收藏"
        case .expand: "扩展"
        case .examples: "例句"
        case .pronounce: "发音"
        case .ask: "生成"
        }
    }

    public var symbol: String {
        switch self {
        case .copy: "doc.on.doc"
        case .translate: "character.book.closed"
        case .parse: "point.3.connected.trianglepath.dotted"
        case .save: "plus"
        case .expand: "arrow.up.right"
        case .examples: "quote.opening"
        case .pronounce: "speaker.wave.2"
        case .ask: "sparkles"
        }
    }

    public var shortcut: String {
        switch self {
        case .copy: "⌘C"
        case .translate: "⌘1"
        case .parse: "⌘2"
        case .save: "⌘S"
        case .expand: "⌘3"
        case .examples: "⌘4"
        case .pronounce: "⌘P"
        case .ask: "Return"
        }
    }
}
