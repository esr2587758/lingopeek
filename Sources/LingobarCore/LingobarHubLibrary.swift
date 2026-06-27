import Foundation

public enum LingobarHubLibraryKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case collection
    case history

    public var id: String { rawValue }
}

public struct LingobarHubLibraryItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var kind: LingobarHubLibraryKind
    public var title: String
    public var visibleText: String
    public var note: String
    public var itemType: String
    public var source: String
    public var createdAt: Date
    public var action: LanguageAction?
    public var copyText: String
    public var sourceText: String

    public init(
        id: UUID,
        kind: LingobarHubLibraryKind,
        title: String,
        visibleText: String,
        note: String,
        itemType: String,
        source: String,
        createdAt: Date,
        action: LanguageAction?,
        copyText: String,
        sourceText: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.visibleText = visibleText
        self.note = note
        self.itemType = itemType
        self.source = source
        self.createdAt = createdAt
        self.action = action
        self.copyText = copyText
        self.sourceText = sourceText
    }
}

public enum LingobarHubLibrary {
    public static func collectionItems(from phrases: [SavedPhrase]) -> [LingobarHubLibraryItem] {
        phrases.map { phrase in
            LingobarHubLibraryItem(
                id: phrase.id,
                kind: .collection,
                title: phrase.title,
                visibleText: phrase.title,
                note: phrase.note,
                itemType: "文本",
                source: "Lingobar",
                createdAt: phrase.createdAt,
                action: nil,
                copyText: phrase.title,
                sourceText: phrase.title
            )
        }
    }

    public static func historyItems(from records: [LingobarHistoryRecord]) -> [LingobarHubLibraryItem] {
        records.map { record in
            LingobarHubLibraryItem(
                id: record.id,
                kind: .history,
                title: record.visibleText,
                visibleText: record.visibleText,
                note: record.note,
                itemType: record.itemType,
                source: record.sourceAppName,
                createdAt: record.createdAt,
                action: record.action,
                copyText: record.copyText,
                sourceText: record.sourceText
            )
        }
    }
}
