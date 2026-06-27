import Foundation

public enum LingobarHistoryLimits {
    public static let defaultRecordLimit = 200
    public static let visibleTextLength = 240
    public static let noteLength = 240
    public static let copyTextLength = 2000
    public static let sourceTextLength = 2000
}

public struct LingobarHistoryRecord: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var action: LanguageAction
    public var itemType: String
    public var visibleText: String
    public var copyText: String
    public var note: String
    public var sourceText: String
    public var sourceAppName: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        action: LanguageAction,
        itemType: String,
        visibleText: String,
        copyText: String,
        note: String,
        sourceText: String,
        sourceAppName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.action = action
        self.itemType = itemType
        self.visibleText = visibleText
        self.copyText = copyText
        self.note = note
        self.sourceText = sourceText
        self.sourceAppName = sourceAppName
        self.createdAt = createdAt
    }

    public static func make(
        action: LanguageAction,
        sourceText: String,
        sourceAppName: String,
        result: LingobarResult,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> LingobarHistoryRecord? {
        switch action {
        case .translate, .grammar, .rewrite, .examples, .pronounce:
            break
        case .copy, .collect:
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
            action: action,
            itemType: bounded(itemType, limit: LingobarHistoryLimits.visibleTextLength),
            visibleText: bounded(visibleText, limit: LingobarHistoryLimits.visibleTextLength),
            copyText: bounded(visibleText, limit: LingobarHistoryLimits.copyTextLength),
            note: bounded(note, limit: LingobarHistoryLimits.noteLength),
            sourceText: bounded(trimmedSourceText, limit: LingobarHistoryLimits.sourceTextLength),
            sourceAppName: normalizedSourceAppName.isEmpty ? "Lingobar" : bounded(normalizedSourceAppName, limit: LingobarHistoryLimits.visibleTextLength),
            createdAt: createdAt
        )
    }
}

public final class LingobarHistoryStore {
    private let fileURL: URL
    private let limit: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileURL: URL, limit: Int = LingobarHistoryLimits.defaultRecordLimit) {
        self.fileURL = fileURL
        self.limit = max(0, limit)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> [LingobarHistoryRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([LingobarHistoryRecord].self, from: data)
    }

    public func save(_ records: [LingobarHistoryRecord]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: [.atomic])
    }

    @discardableResult
    public func append(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord] {
        var records = try load()
        records.insert(record, at: 0)
        let capped = Array(records.prefix(limit))
        try save(capped)
        return capped
    }

    @discardableResult
    public func delete(id: UUID) throws -> [LingobarHistoryRecord] {
        let records = try load().filter { $0.id != id }
        try save(records)
        return records
    }

    public func clear() throws {
        try save([])
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
