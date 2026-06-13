import Foundation

public struct LingobarResult: Equatable, Sendable {
    public var title: String
    public var shortcut: String
    public var summary: String
    public var rows: [LingobarRow]
    public var sideTitle: String
    public var chips: [String]

    public init(
        title: String,
        shortcut: String,
        summary: String,
        rows: [LingobarRow],
        sideTitle: String,
        chips: [String]
    ) {
        self.title = title
        self.shortcut = shortcut
        self.summary = summary
        self.rows = rows
        self.sideTitle = sideTitle
        self.chips = chips
    }
}

public struct LingobarRow: Equatable, Sendable {
    public var label: String
    public var value: String

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
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
