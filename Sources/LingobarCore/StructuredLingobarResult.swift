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
}
