import Foundation

public struct LingobarResult: Codable, Equatable, Sendable {
    public var title: String
    public var shortcut: String
    public var summary: String
    public var rows: [LingobarRow]
    public var sideTitle: String
    public var chips: [String]
    public var moreActionTitle: String
    public var defaultCollectionTitle: String
    public var defaultCollectionItem: DefaultCollectionItem?
    public var learningInsights: LingobarLearningInsights

    public init(
        title: String,
        shortcut: String,
        summary: String,
        rows: [LingobarRow],
        sideTitle: String,
        chips: [String],
        moreActionTitle: String = "",
        defaultCollectionTitle: String = "",
        defaultCollectionItem: DefaultCollectionItem? = nil,
        learningInsights: LingobarLearningInsights = .empty
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
        self.learningInsights = learningInsights
    }

    enum CodingKeys: String, CodingKey {
        case title
        case shortcut
        case summary
        case rows
        case sideTitle
        case chips
        case moreActionTitle
        case defaultCollectionTitle
        case defaultCollectionItem
        case learningInsights
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultCollectionItem = try container.decodeIfPresent(DefaultCollectionItem.self, forKey: .defaultCollectionItem)
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title) ?? "结果",
            shortcut: try container.decodeIfPresent(String.self, forKey: .shortcut) ?? "",
            summary: try container.decodeIfPresent(String.self, forKey: .summary) ?? "",
            rows: try container.decodeIfPresent([LingobarRow].self, forKey: .rows) ?? [],
            sideTitle: try container.decodeIfPresent(String.self, forKey: .sideTitle) ?? "后续动作",
            chips: try container.decodeIfPresent([String].self, forKey: .chips) ?? [],
            moreActionTitle: try container.decodeIfPresent(String.self, forKey: .moreActionTitle) ?? "",
            defaultCollectionTitle: try container.decodeIfPresent(String.self, forKey: .defaultCollectionTitle) ?? "",
            defaultCollectionItem: defaultCollectionItem,
            learningInsights: try container.decodeIfPresent(LingobarLearningInsights.self, forKey: .learningInsights) ?? .empty
        )
    }
}

public struct LingobarLearningInsights: Codable, Equatable, Sendable {
    public static let empty = LingobarLearningInsights(
        collocations: [],
        phrases: [],
        grammarPoints: []
    )

    public var collocations: [GrammarCollocation]
    public var phrases: [GrammarPhrase]
    public var grammarPoints: [GrammarPoint]

    public init(
        collocations: [GrammarCollocation],
        phrases: [GrammarPhrase],
        grammarPoints: [GrammarPoint]
    ) {
        self.collocations = collocations
        self.phrases = phrases
        self.grammarPoints = grammarPoints
    }

    public var isEmpty: Bool {
        collocations.isEmpty && phrases.isEmpty && grammarPoints.isEmpty
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
    public var type: String
    public var sourceText: String
    public var sourceAppName: String
    public var sourceAction: LanguageAction?
    public var sourceActionID: String?
    public var sourceActionTitle: String?
    public var resultSnapshot: LingobarResult?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        note: String,
        type: String = "文本",
        sourceText: String = "",
        sourceAppName: String = "Lingobar",
        sourceAction: LanguageAction? = nil,
        sourceActionID: String? = nil,
        sourceActionTitle: String? = nil,
        resultSnapshot: LingobarResult? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.type = type
        self.sourceText = sourceText
        self.sourceAppName = sourceAppName
        self.sourceAction = sourceAction
        self.sourceActionID = sourceActionID ?? sourceAction?.actionID
        self.sourceActionTitle = sourceActionTitle ?? sourceAction?.title
        self.resultSnapshot = resultSnapshot
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case type
        case sourceText
        case sourceAppName
        case sourceAction
        case sourceActionID
        case sourceActionTitle
        case resultSnapshot
        case createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceAction = try container.decodeIfPresent(LanguageAction.self, forKey: .sourceAction)
        self.init(
            id: try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            title: try container.decodeIfPresent(String.self, forKey: .title) ?? "",
            note: try container.decodeIfPresent(String.self, forKey: .note) ?? "",
            type: try container.decodeIfPresent(String.self, forKey: .type) ?? "文本",
            sourceText: try container.decodeIfPresent(String.self, forKey: .sourceText) ?? "",
            sourceAppName: try container.decodeIfPresent(String.self, forKey: .sourceAppName) ?? "Lingobar",
            sourceAction: sourceAction,
            sourceActionID: try container.decodeIfPresent(String.self, forKey: .sourceActionID) ?? sourceAction?.actionID,
            sourceActionTitle: try container.decodeIfPresent(String.self, forKey: .sourceActionTitle) ?? sourceAction?.title,
            resultSnapshot: try container.decodeIfPresent(LingobarResult.self, forKey: .resultSnapshot),
            createdAt: try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        )
    }
}
