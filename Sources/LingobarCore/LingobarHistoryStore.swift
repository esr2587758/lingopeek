import Foundation

public enum LingobarHistoryLimits {
    public static let defaultRecordLimit = 50
    public static let visibleTextLength = 240
    public static let noteLength = 240
    public static let copyTextLength = 2000
    public static let sourceTextLength = 2000
}

public struct LingobarStoredResultSnapshot: Equatable, Codable, Sendable {
    public var result: LingobarResult
    public var grammarResult: GrammarResult?

    public init(
        result: LingobarResult,
        grammarResult: GrammarResult? = nil
    ) {
        self.result = result
        self.grammarResult = grammarResult
    }

    enum CodingKeys: String, CodingKey {
        case result
        case grammarResult
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.contains(.result) || container.contains(.grammarResult) {
            let result = try container.decodeIfPresent(LingobarResult.self, forKey: .result)
            self.init(
                result: result ?? LingobarResult(
                    title: "结果",
                    shortcut: "",
                    summary: "",
                    rows: [],
                    sideTitle: "后续动作",
                    chips: []
                ),
                grammarResult: try container.decodeIfPresent(GrammarResult.self, forKey: .grammarResult)
            )
            return
        }

        self.init(result: try LingobarResult(from: decoder))
    }
}

public struct LingobarHistoryRecord: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var action: LanguageAction
    public var actionID: String
    public var actionTitle: String
    public var itemType: String
    public var visibleText: String
    public var copyText: String
    public var note: String
    public var sourceText: String
    public var sourceAppName: String
    public var resultSnapshot: LingobarResult
    public var resultSnapshots: [String: LingobarStoredResultSnapshot]
    public var isSaved: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        action: LanguageAction,
        actionID: String? = nil,
        actionTitle: String? = nil,
        itemType: String,
        visibleText: String,
        copyText: String,
        note: String,
        sourceText: String,
        sourceAppName: String,
        resultSnapshot: LingobarResult? = nil,
        grammarSnapshot: GrammarResult? = nil,
        resultSnapshots: [String: LingobarStoredResultSnapshot] = [:],
        isSaved: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        let resolvedActionID = actionID ?? action.actionID
        let resolvedActionTitle = actionTitle ?? action.title
        let primarySnapshot = resultSnapshot ?? resultSnapshots[resolvedActionID]?.result ?? resultSnapshots[action.rawValue]?.result ?? LingobarHistoryRecord.legacySnapshot(
            action: action,
            actionTitle: resolvedActionTitle,
            visibleText: visibleText,
            note: note,
            itemType: itemType
        )
        var snapshots = resultSnapshots
        snapshots[resolvedActionID] = LingobarStoredResultSnapshot(
            result: primarySnapshot,
            grammarResult: grammarSnapshot ?? snapshots[resolvedActionID]?.grammarResult
        )
        self.id = id
        self.action = action
        self.actionID = resolvedActionID
        self.actionTitle = resolvedActionTitle
        self.itemType = itemType
        self.visibleText = visibleText
        self.copyText = copyText
        self.note = note
        self.sourceText = sourceText
        self.sourceAppName = sourceAppName
        self.resultSnapshot = primarySnapshot
        self.resultSnapshots = snapshots
        self.isSaved = isSaved
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case actionID
        case actionTitle
        case itemType
        case visibleText
        case copyText
        case note
        case sourceText
        case sourceAppName
        case resultSnapshot
        case resultSnapshots
        case isSaved
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decodeIfPresent(LanguageAction.self, forKey: .action) ?? .translate
        let actionID = try container.decodeIfPresent(String.self, forKey: .actionID) ?? action.actionID
        let actionTitle = try container.decodeIfPresent(String.self, forKey: .actionTitle) ?? action.title
        let itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? "文本"
        let visibleText = try container.decodeIfPresent(String.self, forKey: .visibleText) ?? ""
        let note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        let resultSnapshot = try container.decodeIfPresent(LingobarResult.self, forKey: .resultSnapshot)
        let resultSnapshots = try container.decodeIfPresent([String: LingobarStoredResultSnapshot].self, forKey: .resultSnapshots) ?? [:]
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.init(
            id: try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            action: action,
            actionID: actionID,
            actionTitle: actionTitle,
            itemType: itemType,
            visibleText: visibleText,
            copyText: try container.decodeIfPresent(String.self, forKey: .copyText) ?? visibleText,
            note: note,
            sourceText: try container.decodeIfPresent(String.self, forKey: .sourceText) ?? "",
            sourceAppName: try container.decodeIfPresent(String.self, forKey: .sourceAppName) ?? "Lingobar",
            resultSnapshot: resultSnapshot,
            resultSnapshots: resultSnapshots,
            isSaved: try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false,
            createdAt: createdAt,
            updatedAt: try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        )
    }

    public static func make(
        action: LanguageAction,
        sourceText: String,
        sourceAppName: String,
        result: LingobarResult,
        grammarSnapshot: GrammarResult? = nil,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> LingobarHistoryRecord? {
        make(
            action: LingobarActionDescriptor(builtInAction: action),
            sourceText: sourceText,
            sourceAppName: sourceAppName,
            result: result,
            grammarSnapshot: grammarSnapshot,
            createdAt: createdAt,
            id: id
        )
    }

    public static func make(
        action: LingobarActionDescriptor,
        sourceText: String,
        sourceAppName: String,
        result: LingobarResult,
        grammarSnapshot: GrammarResult? = nil,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> LingobarHistoryRecord? {
        let fallbackAction = action.builtInAction ?? .rewrite
        guard action.isResultProducing else {
            return nil
        }

        let trimmedSourceText = sourceText.trimmedForHistory
        guard !trimmedSourceText.isEmpty else {
            return nil
        }

        let collectionItem = result.defaultCollectionItem
        let visibleText = firstNonEmpty([
            collectionItem?.title,
            result.defaultCollectionTitle,
            result.summary
        ])
        let note = firstNonEmpty([
            collectionItem?.note,
            result.summary
        ])
        let itemType = firstNonEmpty([
            collectionItem?.type,
            "文本"
        ])
        let normalizedSourceAppName = sourceAppName.trimmedForHistory

        return LingobarHistoryRecord(
            id: id,
            action: fallbackAction,
            actionID: action.id,
            actionTitle: action.title,
            itemType: bounded(itemType, limit: LingobarHistoryLimits.visibleTextLength),
            visibleText: bounded(visibleText, limit: LingobarHistoryLimits.visibleTextLength),
            copyText: bounded(visibleText, limit: LingobarHistoryLimits.copyTextLength),
            note: bounded(note, limit: LingobarHistoryLimits.noteLength),
            sourceText: bounded(trimmedSourceText, limit: LingobarHistoryLimits.sourceTextLength),
            sourceAppName: normalizedSourceAppName.isEmpty ? "Lingobar" : bounded(normalizedSourceAppName, limit: LingobarHistoryLimits.visibleTextLength),
            resultSnapshot: result,
            grammarSnapshot: grammarSnapshot,
            createdAt: createdAt
        )
    }

    public func snapshot(for action: LanguageAction) -> LingobarResult? {
        storedSnapshot(for: action.actionID)?.result
    }

    public func storedSnapshot(for action: LanguageAction) -> LingobarStoredResultSnapshot? {
        storedSnapshot(for: action.actionID)
    }

    public func storedSnapshot(for actionID: String) -> LingobarStoredResultSnapshot? {
        resultSnapshots[actionID]
    }

    func merged(with newer: LingobarHistoryRecord, markSaved: Bool = false) -> LingobarHistoryRecord {
        var snapshots = resultSnapshots
        for (action, snapshot) in newer.resultSnapshots {
            snapshots[action] = snapshot
        }
        return LingobarHistoryRecord(
            id: id,
            action: newer.action,
            actionID: newer.actionID,
            actionTitle: newer.actionTitle,
            itemType: newer.itemType,
            visibleText: newer.visibleText,
            copyText: newer.copyText,
            note: newer.note,
            sourceText: newer.sourceText,
            sourceAppName: newer.sourceAppName,
            resultSnapshot: newer.resultSnapshot,
            grammarSnapshot: newer.storedSnapshot(for: newer.actionID)?.grammarResult,
            resultSnapshots: snapshots,
            isSaved: isSaved || newer.isSaved || markSaved,
            createdAt: createdAt,
            updatedAt: max(updatedAt, newer.updatedAt)
        )
    }

    func absorbingSnapshots(from older: LingobarHistoryRecord) -> LingobarHistoryRecord {
        var snapshots = older.resultSnapshots
        for (action, snapshot) in resultSnapshots {
            snapshots[action] = snapshot
        }
        return LingobarHistoryRecord(
            id: id,
            action: action,
            actionID: actionID,
            actionTitle: actionTitle,
            itemType: itemType,
            visibleText: visibleText,
            copyText: copyText,
            note: note,
            sourceText: sourceText,
            sourceAppName: sourceAppName,
            resultSnapshot: resultSnapshot,
            grammarSnapshot: storedSnapshot(for: actionID)?.grammarResult,
            resultSnapshots: snapshots,
            isSaved: isSaved || older.isSaved,
            createdAt: min(createdAt, older.createdAt),
            updatedAt: max(updatedAt, older.updatedAt)
        )
    }

    private static func legacySnapshot(
        action: LanguageAction,
        actionTitle: String,
        visibleText: String,
        note: String,
        itemType: String
    ) -> LingobarResult {
        let summary = note.isEmpty ? visibleText : note
        return LingobarResult(
            title: actionTitle,
            shortcut: action.shortcut,
            summary: summary,
            rows: [LingobarRow(itemType.isEmpty ? "文本" : itemType, visibleText)],
            sideTitle: "后续动作",
            chips: [],
            moreActionTitle: action.moreActionTitle,
            defaultCollectionItem: DefaultCollectionItem(
                title: visibleText,
                note: note,
                type: itemType.isEmpty ? "文本" : itemType
            )
        )
    }
}

public final class LingobarHistoryStore: @unchecked Sendable {
    private let fileURL: URL
    private let limit: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public init(fileURL: URL, limit: Int = LingobarHistoryLimits.defaultRecordLimit) {
        self.fileURL = fileURL
        self.limit = max(0, limit)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public static func defaultStore() -> LingobarHistoryStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appending(path: "LingoPeek", directoryHint: .isDirectory)
        return LingobarHistoryStore(fileURL: directory.appending(path: "history.json"))
    }

    public func load() throws -> [LingobarHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }

        return try loadUnlocked()
    }

    public func save(_ records: [LingobarHistoryRecord]) throws {
        lock.lock()
        defer { lock.unlock() }

        try saveUnlocked(records)
    }

    @discardableResult
    public func append(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }

        var records = try loadUnlocked()
        upsert(record, into: &records, markSaved: false)
        let capped = capped(records)
        try saveUnlocked(capped)
        return capped
    }

    @discardableResult
    public func delete(id: UUID) throws -> [LingobarHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }

        let records = try loadUnlocked().filter { $0.id != id }
        try saveUnlocked(records)
        return records
    }

    @discardableResult
    public func setSaved(id: UUID, isSaved: Bool = true) throws -> [LingobarHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }

        var records = try loadUnlocked()
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return records
        }
        records[index].isSaved = isSaved
        let capped = capped(records)
        try saveUnlocked(capped)
        return capped
    }

    @discardableResult
    public func saveOrAppend(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }

        var savedRecord = record
        savedRecord.isSaved = true
        var records = try loadUnlocked()
        upsert(savedRecord, into: &records, markSaved: true)
        let capped = capped(records)
        try saveUnlocked(capped)
        return capped
    }

    public func clear() throws {
        lock.lock()
        defer { lock.unlock() }

        try saveUnlocked([])
    }

    private func loadUnlocked() throws -> [LingobarHistoryRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return coalesced(try decoder.decode([LingobarHistoryRecord].self, from: data))
    }

    private func saveUnlocked(_ records: [LingobarHistoryRecord]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(capped(coalesced(records)))
        try data.write(to: fileURL, options: [.atomic])
    }

    private func upsert(
        _ record: LingobarHistoryRecord,
        into records: inout [LingobarHistoryRecord],
        markSaved: Bool
    ) {
        if let index = records.firstIndex(where: { $0.matchesHistoryIdentity(of: record) }) {
            let merged = records[index].merged(with: record, markSaved: markSaved)
            records.remove(at: index)
            records.insert(merged, at: 0)
        } else {
            var inserted = record
            inserted.isSaved = inserted.isSaved || markSaved
            records.insert(inserted, at: 0)
        }
    }

    private func capped(_ records: [LingobarHistoryRecord]) -> [LingobarHistoryRecord] {
        var unsavedCount = 0
        return records.filter { record in
            if record.isSaved {
                return true
            }
            guard unsavedCount < limit else {
                return false
            }
            unsavedCount += 1
            return true
        }
    }

    private func coalesced(_ records: [LingobarHistoryRecord]) -> [LingobarHistoryRecord] {
        var result: [LingobarHistoryRecord] = []
        for record in records {
            if let index = result.firstIndex(where: { $0.matchesHistoryIdentity(of: record) }) {
                result[index] = result[index].absorbingSnapshots(from: record)
            } else {
                result.append(record)
            }
        }
        return result
    }
}

private extension LingobarHistoryRecord {
    var historySourceKey: String {
        sourceText.trimmedForHistory
    }

    func matchesHistoryIdentity(of other: LingobarHistoryRecord) -> Bool {
        if id == other.id {
            return true
        }
        let key = historySourceKey
        return !key.isEmpty && key == other.historySourceKey
    }
}

private func firstNonEmpty(_ values: [String?]) -> String {
    values.lazy
        .compactMap { $0?.trimmedForHistory }
        .first { !$0.isEmpty } ?? ""
}

private func bounded(_ value: String, limit: Int) -> String {
    guard value.count > limit else {
        return value
    }
    return String(value.prefix(limit))
}

private extension String {
    var trimmedForHistory: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
