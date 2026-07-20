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
    public var updatedAt: Date
    public var action: LanguageAction?
    public var actionID: String
    public var actionTitle: String
    public var copyText: String
    public var sourceText: String
    public var resultSnapshot: LingobarResult?
    public var resultSnapshots: [String: LingobarStoredResultSnapshot]
    public var isSaved: Bool

    public init(
        id: UUID,
        kind: LingobarHubLibraryKind,
        title: String,
        visibleText: String,
        note: String,
        itemType: String,
        source: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        action: LanguageAction?,
        actionID: String? = nil,
        actionTitle: String? = nil,
        copyText: String,
        sourceText: String,
        resultSnapshot: LingobarResult? = nil,
        resultSnapshots: [String: LingobarStoredResultSnapshot] = [:],
        isSaved: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.visibleText = visibleText
        self.note = note
        self.itemType = itemType
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.action = action
        self.actionID = actionID ?? action?.actionID ?? LanguageAction.translate.actionID
        self.actionTitle = actionTitle ?? action?.title ?? "翻译"
        self.copyText = copyText
        self.sourceText = sourceText
        self.resultSnapshot = resultSnapshot
        self.resultSnapshots = resultSnapshots
        self.isSaved = isSaved
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
                itemType: phrase.type,
                source: phrase.sourceAppName,
                createdAt: phrase.createdAt,
                action: phrase.sourceAction,
                actionID: phrase.sourceActionID ?? phrase.sourceAction?.actionID,
                actionTitle: phrase.sourceActionTitle ?? phrase.sourceAction?.title,
                copyText: phrase.title,
                sourceText: phrase.sourceText.isEmpty ? phrase.title : phrase.sourceText,
                resultSnapshot: phrase.resultSnapshot,
                resultSnapshots: phrase.resultSnapshot.map { snapshot in
                    [LingobarHubLibrary.snapshotKey(for: phrase): LingobarStoredResultSnapshot(result: snapshot)]
                } ?? [:]
            )
        }
    }

    public static func historyItems(from records: [LingobarHistoryRecord]) -> [LingobarHubLibraryItem] {
        records.map { record in
            let historyTitle = record.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? record.visibleText
                : record.sourceText
            return LingobarHubLibraryItem(
                id: record.id,
                kind: .history,
                title: historyTitle,
                visibleText: historyTitle,
                note: record.note,
                itemType: record.itemType,
                source: record.sourceAppName,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                action: record.action,
                actionID: record.actionID,
                actionTitle: record.actionTitle,
                copyText: record.copyText,
                sourceText: record.sourceText,
                resultSnapshot: record.resultSnapshot,
                resultSnapshots: record.resultSnapshots,
                isSaved: record.isSaved
            )
        }
    }

    private static func snapshotKey(for phrase: SavedPhrase) -> String {
        phrase.sourceActionID ?? phrase.sourceAction?.actionID ?? LanguageAction.translate.actionID
    }
}
