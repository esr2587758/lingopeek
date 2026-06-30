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

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case title
        case name
        case text
        case content
        case result
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.label = "结果"
            self.value = value
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "结果"
        self.value = try container.decodeIfPresent(String.self, forKey: .value)
            ?? container.decodeIfPresent(String.self, forKey: .text)
            ?? container.decodeIfPresent(String.self, forKey: .content)
            ?? container.decodeIfPresent(String.self, forKey: .result)
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(value, forKey: .value)
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

    enum CodingKeys: String, CodingKey {
        case title
        case note
        case type
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.title = value
            self.note = ""
            self.type = "文本"
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "文本"
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
