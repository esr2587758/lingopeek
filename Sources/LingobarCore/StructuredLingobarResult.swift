public struct StructuredLingobarResult: Codable, Equatable, Sendable {
    public var title: String
    public var summary: String
    public var rows: [LingobarRow]
    public var chips: [String]
    public var moreActionTitle: String
    public var defaultCollectionItem: DefaultCollectionItem

    public init(
        title: String,
        summary: String,
        rows: [LingobarRow],
        chips: [String],
        moreActionTitle: String,
        defaultCollectionItem: DefaultCollectionItem
    ) {
        self.title = title
        self.summary = summary
        self.rows = rows
        self.chips = chips
        self.moreActionTitle = moreActionTitle
        self.defaultCollectionItem = defaultCollectionItem
    }

    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case rows
        case chips
        case moreActionTitle
        case defaultCollectionItem
        case variants
        case rewrites
        case examples
        case translations
        case result
        case text
        case rewrite
        case rewritten
        case natural
        case primary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "结果"

        let rows = try Self.decodeRows(from: container)
        let summary = try Self.decodeSummary(from: container, rows: rows)
        self.summary = summary.isEmpty ? rows.first?.value ?? "" : summary
        self.rows = rows.isEmpty ? [LingobarRow("结果", self.summary)] : rows
        self.chips = try Self.decodeChips(from: container)
        self.moreActionTitle = try container.decodeIfPresent(String.self, forKey: .moreActionTitle) ?? ""
        self.defaultCollectionItem = try container.decodeIfPresent(DefaultCollectionItem.self, forKey: .defaultCollectionItem)
            ?? DefaultCollectionItem(title: self.rows.first?.value ?? self.summary, note: self.summary, type: "文本")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(rows, forKey: .rows)
        try container.encode(chips, forKey: .chips)
        try container.encode(moreActionTitle, forKey: .moreActionTitle)
        try container.encode(defaultCollectionItem, forKey: .defaultCollectionItem)
    }

    public func lingobarResult(shortcut: String) -> LingobarResult {
        LingobarResult(
            title: title,
            shortcut: shortcut,
            summary: summary,
            rows: rows,
            sideTitle: "后续动作",
            chips: chips,
            moreActionTitle: moreActionTitle,
            defaultCollectionItem: defaultCollectionItem
        )
    }

    private static func decodeSummary(from container: KeyedDecodingContainer<CodingKeys>, rows: [LingobarRow]) throws -> String {
        for key in [CodingKeys.summary, .result, .text, .rewrite, .rewritten, .natural, .primary] {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }
        return rows.first?.value ?? ""
    }

    private static func decodeRows(from container: KeyedDecodingContainer<CodingKeys>) throws -> [LingobarRow] {
        if let rows = try container.decodeIfPresent([LingobarRow].self, forKey: .rows) {
            return rows.filter { !$0.value.isEmpty }
        }
        if let rows = try decodeRowsValue(from: container, forKey: .rows), !rows.isEmpty {
            return rows
        }
        for key in [CodingKeys.variants, .rewrites, .examples, .translations] {
            if let rows = try decodeRowsValue(from: container, forKey: key), !rows.isEmpty {
                return rows
            }
        }

        var rows: [LingobarRow] = []
        for (label, key) in [
            ("自然版", CodingKeys.natural),
            ("主版本", .primary),
            ("结果", .result),
            ("文本", .text),
            ("改写", .rewrite),
            ("改写", .rewritten)
        ] {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                rows.append(LingobarRow(label, value))
            }
        }
        return rows
    }

    private static func decodeRowsValue(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [LingobarRow]? {
        if let rows = try? container.decodeIfPresent([LingobarRow].self, forKey: key) {
            return rows
        }
        if let values = try? container.decodeIfPresent([String].self, forKey: key) {
            return values.enumerated().map { index, value in LingobarRow("版本 \(index + 1)", value) }
        }
        if let values = try? container.decodeIfPresent([String: String].self, forKey: key) {
            return values
                .sorted { $0.key < $1.key }
                .map { LingobarRow($0.key, $0.value) }
        }
        return nil
    }

    private static func decodeChips(from container: KeyedDecodingContainer<CodingKeys>) throws -> [String] {
        if let chips = try? container.decodeIfPresent([String].self, forKey: .chips) {
            return chips
        }
        if let chip = try? container.decodeIfPresent(String.self, forKey: .chips), !chip.isEmpty {
            return [chip]
        }
        return []
    }
}
