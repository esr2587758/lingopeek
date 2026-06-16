import Foundation

public struct LingobarResult: Equatable, Sendable {
    public var title: String
    public var shortcut: String
    public var summary: String
    public var rows: [LingobarRow]
    public var sideTitle: String
    public var chips: [String]
    public var moreActionTitle: String
    public var defaultCollectionTitle: String
    public var defaultCollectionItem: DefaultCollectionItem?

    public init(
        title: String,
        shortcut: String,
        summary: String,
        rows: [LingobarRow],
        sideTitle: String,
        chips: [String],
        moreActionTitle: String = "",
        defaultCollectionTitle: String = "",
        defaultCollectionItem: DefaultCollectionItem? = nil
    ) {
        self.title = title
        self.shortcut = shortcut
        self.summary = summary
        self.rows = rows
        self.sideTitle = sideTitle
        self.chips = chips
        self.moreActionTitle = moreActionTitle
        self.defaultCollectionTitle = defaultCollectionTitle.isEmpty ? defaultCollectionItem?.title ?? "" : defaultCollectionTitle
        self.defaultCollectionItem = defaultCollectionItem
    }
}

public struct LingobarRow: Codable, Equatable, Sendable {
    public var label: String
    public var value: String

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

public struct DefaultCollectionItem: Codable, Equatable, Sendable {
    public var title: String
    public var note: String
    public var type: String

    public init(title: String, note: String, type: String) {
        self.title = title
        self.note = note
        self.type = type
    }
}

public struct SavedPhrase: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var note: String
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, note: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.note = note
        self.createdAt = createdAt
    }
}
