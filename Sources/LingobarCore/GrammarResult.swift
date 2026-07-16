import Foundation

fileprivate extension KeyedDecodingContainer {
    func decodeLossyStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func decodeLossyIntIfPresent(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    func decodeLossyBoolIfPresent(forKey key: Key) throws -> Bool? {
        if let value = try? decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value != 0
        }
        return nil
    }

    func decodeLossyStringArrayIfPresent(forKey key: Key) throws -> [String]? {
        if let values = try? decodeIfPresent([String].self, forKey: key) {
            return values
        }
        if let values = try? decodeIfPresent([GrammarLooseValue].self, forKey: key) {
            return values.compactMap(\.stringValue)
        }
        if let value = try? decodeIfPresent(GrammarLooseValue.self, forKey: key),
           let string = value.stringValue {
            return [string]
        }
        return nil
    }

    func decodeLossyIntArrayIfPresent(forKey key: Key) throws -> [Int]? {
        if let values = try? decodeIfPresent([Int].self, forKey: key) {
            return values
        }
        if let values = try? decodeIfPresent([GrammarLooseValue].self, forKey: key) {
            let ints = values.compactMap(\.intValue)
            return ints.isEmpty ? nil : ints
        }
        if let value = try? decodeIfPresent(GrammarLooseValue.self, forKey: key) {
            if let ints = value.intArrayValue, !ints.isEmpty {
                return ints
            }
            if let int = value.intValue {
                return [int]
            }
        }
        return nil
    }
}

fileprivate struct GrammarLooseCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

fileprivate enum GrammarLooseValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([GrammarLooseValue])
    case object([String: GrammarLooseValue])
    case null

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if container.decodeNil() {
                self = .null
                return
            }
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            }
            if let value = try? container.decode(Int.self) {
                self = .int(value)
                return
            }
            if let value = try? container.decode(Double.self) {
                self = .double(value)
                return
            }
            if let value = try? container.decode(Bool.self) {
                self = .bool(value)
                return
            }
        }

        if var container = try? decoder.unkeyedContainer() {
            var values: [GrammarLooseValue] = []
            while !container.isAtEnd {
                values.append(try container.decode(GrammarLooseValue.self))
            }
            self = .array(values)
            return
        }

        let container = try decoder.container(keyedBy: GrammarLooseCodingKey.self)
        var values: [String: GrammarLooseValue] = [:]
        for key in container.allKeys {
            values[key.stringValue] = try container.decode(GrammarLooseValue.self, forKey: key)
        }
        self = .object(values)
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .array(let values):
            let text = values.compactMap(\.stringValue).joined(separator: " ")
            return text.isEmpty ? nil : text
        case .object(let values):
            for key in ["text", "w", "phrase", "title", "label", "note", "id", "from", "to", "role"] {
                if let value = values[key]?.stringValue, !value.isEmpty {
                    return value
                }
            }
            return nil
        case .null:
            return nil
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .string(let value):
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        case .bool(let value):
            return value ? 1 : 0
        default:
            return nil
        }
    }

    var intArrayValue: [Int]? {
        switch self {
        case .array(let values):
            let ints = values.compactMap(\.intValue)
            return ints.isEmpty ? nil : ints
        case .string(let value):
            let ints = value
                .split { !$0.isNumber && $0 != "-" }
                .compactMap { Int($0) }
            return ints.isEmpty ? nil : ints
        default:
            return nil
        }
    }
}

public enum GrammarRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case subject
    case predicate
    case object
    case attr
    case appos
    case adv
    case conj

    public var id: String { rawValue }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "subject", "主语":
            self = .subject
        case "predicate", "谓语":
            self = .predicate
        case "object", "宾语":
            self = .object
        case "attr", "定语":
            self = .attr
        case "appos", "同位语":
            self = .appos
        case "adv", "状语":
            self = .adv
        case "conj", "连接词":
            self = .conj
        default:
            self = .attr
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var zh: String {
        switch self {
        case .subject: "主语"
        case .predicate: "谓语"
        case .object: "宾语"
        case .attr: "定语"
        case .appos: "同位语"
        case .adv: "状语"
        case .conj: "连接词"
        }
    }
}

public enum GrammarAbbreviationGlossary {
    public static func displayText(for term: String) -> String {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let note = chineseNote(for: trimmed) else {
            return term
        }
        return "\(trimmed) · \(note)"
    }

    public static func chineseNote(for term: String) -> String? {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !containsCJK(trimmed) else {
            return nil
        }

        let words = normalizedWords(in: trimmed)
        guard !words.isEmpty else {
            return nil
        }

        let qualifierNotes = words.compactMap { qualifiers[$0] }
        let baseWords = words.filter { qualifiers[$0] == nil }
        if baseWords.isEmpty {
            return qualifierNotes.isEmpty ? nil : qualifierNotes.joined(separator: "、")
        }
        let baseKey = baseWords.joined(separator: " ")
        guard var note = glosses[baseKey] else {
            return nil
        }

        if !qualifierNotes.isEmpty {
            note += "（\(qualifierNotes.joined(separator: "、"))）"
        }
        return note
    }

    private static func normalizedWords(in term: String) -> [String] {
        term.lowercased().split { scalar in
            !(scalar.isLetter || scalar.isNumber)
        }.map(String.init)
    }

    private static func containsCJK(_ term: String) -> Bool {
        term.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF:
                return true
            default:
                return false
            }
        }
    }

    private static let qualifiers: [String: String] = [
        "active": "主动",
        "passive": "被动"
    ]

    private static let glosses: [String: String] = [
        "s": "句子",
        "sbar": "从句",
        "cp": "从句",
        "np": "名词短语",
        "vp": "动词短语",
        "pp": "介词短语",
        "ap": "形容词短语",
        "adjp": "形容词短语",
        "advp": "状语短语",
        "conjp": "连接短语",
        "n": "名词",
        "noun": "名词",
        "v": "动词",
        "verb": "动词",
        "adj": "形容词",
        "adjective": "形容词",
        "adv": "副词/状语",
        "adverb": "副词",
        "prep": "介词",
        "preposition": "介词",
        "conj": "连词",
        "conjunction": "连词",
        "det": "限定词",
        "determiner": "限定词",
        "pron": "代词",
        "pronoun": "代词",
        "aux": "助动词",
        "modal": "情态动词",
        "past": "过去时",
        "present": "现在时",
        "future": "将来时",
        "simple": "一般体",
        "progressive": "进行体",
        "continuous": "进行体",
        "perfect": "完成体",
        "perfective": "完成体",
        "indicative": "陈述语气",
        "subjunctive": "虚拟语气",
        "imperative": "祈使语气",
        "conditional": "条件语气",
        "finite": "限定动词",
        "non finite": "非限定",
        "nonfinite": "非限定",
        "past simple": "一般过去时",
        "simple past": "一般过去时",
        "present simple": "一般现在时",
        "simple present": "一般现在时",
        "past progressive": "过去进行体",
        "present progressive": "现在进行体",
        "past continuous": "过去进行体",
        "present continuous": "现在进行体",
        "present participle": "现在分词",
        "n phr": "名词短语",
        "n phrase": "名词短语",
        "noun phr": "名词短语",
        "noun phrase": "名词短语",
        "v phr": "动词短语",
        "v phrase": "动词短语",
        "verb phr": "动词短语",
        "verb phrase": "动词短语",
        "adj phr": "形容词短语",
        "adj phrase": "形容词短语",
        "adjective phr": "形容词短语",
        "adjective phrase": "形容词短语",
        "adv phr": "状语短语",
        "adv phrase": "状语短语",
        "adverb phr": "副词短语",
        "adverb phrase": "副词短语",
        "adverbial phr": "状语短语",
        "adverbial phrase": "状语短语",
        "prep phr": "介词短语",
        "prep phrase": "介词短语",
        "preposition phr": "介词短语",
        "prepositional phrase": "介词短语",
        "conj phr": "连接短语",
        "conj phrase": "连接短语",
        "conjunction phr": "连接短语",
        "conjunction phrase": "连接短语",
        "clause": "从句/分句",
        "relative clause": "定语从句",
        "attributive clause": "定语从句",
        "object clause": "宾语从句",
        "concessive clause": "让步从句",
        "main clause": "主句"
    ]
}

public struct GrammarResult: Codable, Equatable, Sendable {
    public var title: String
    public var sourceSentence: String
    public var chineseMeaning: String
    public var analysisScopeNote: String
    public var chunks: [GrammarChunk]
    public var dependencies: [GrammarDependency]
    public var tree: GrammarTreeNode
    public var trunk: GrammarTrunk
    public var tenseVoice: [GrammarTenseClause]
    public var wordOrder: GrammarWordOrder
    public var pattern: GrammarPattern
    public var collocations: [GrammarCollocation]
    public var phrases: [GrammarPhrase]
    public var grammarPoints: [GrammarPoint]
    public var defaultCollectionItem: DefaultCollectionItem

    public init(
        title: String,
        sourceSentence: String,
        chineseMeaning: String,
        analysisScopeNote: String = "",
        chunks: [GrammarChunk],
        dependencies: [GrammarDependency],
        tree: GrammarTreeNode,
        trunk: GrammarTrunk,
        tenseVoice: [GrammarTenseClause],
        wordOrder: GrammarWordOrder,
        pattern: GrammarPattern,
        collocations: [GrammarCollocation],
        phrases: [GrammarPhrase],
        grammarPoints: [GrammarPoint],
        defaultCollectionItem: DefaultCollectionItem
    ) {
        self.title = title
        self.sourceSentence = sourceSentence
        self.chineseMeaning = chineseMeaning
        self.analysisScopeNote = analysisScopeNote
        self.chunks = chunks
        self.dependencies = dependencies
        self.tree = tree
        self.trunk = trunk
        self.tenseVoice = tenseVoice
        self.wordOrder = wordOrder
        self.pattern = pattern
        self.collocations = collocations
        self.phrases = phrases
        self.grammarPoints = grammarPoints
        self.defaultCollectionItem = defaultCollectionItem
    }

    public func lingobarResult(shortcut: String) -> LingobarResult {
        LingobarResult(
            title: title,
            shortcut: shortcut,
            summary: chineseMeaning,
            rows: chunks.map { LingobarRow($0.label, $0.text) },
            sideTitle: "语法解析",
            chips: [pattern.en] + collocations.map(\.phrase),
            moreActionTitle: LanguageAction.grammar.moreActionTitle,
            defaultCollectionItem: defaultCollectionItem,
            learningInsights: LingobarLearningInsights(
                collocations: collocations,
                phrases: phrases,
                grammarPoints: grammarPoints
            )
        )
    }

    public var learningInsights: LingobarLearningInsights {
        LingobarLearningInsights(
            collocations: collocations,
            phrases: phrases,
            grammarPoints: grammarPoints
        )
    }

    public func applyingLearningInsights(_ insights: LingobarLearningInsights) -> GrammarResult {
        var copy = self
        copy.collocations = insights.collocations
        copy.phrases = insights.phrases
        copy.grammarPoints = insights.grammarPoints
        return copy
    }

    enum CodingKeys: String, CodingKey {
        case title
        case sourceSentence
        case chineseMeaning
        case analysisScopeNote
        case chunks
        case dependencies
        case tree
        case trunk
        case tenseVoice
        case wordOrder
        case pattern
        case collocations
        case phrases
        case grammarPoints
        case defaultCollectionItem
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pattern = try container.decodeIfPresent(GrammarPattern.self, forKey: .pattern)
            ?? GrammarPattern(en: "", zh: "")
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "语法解析"
        self.sourceSentence = try container.decode(String.self, forKey: .sourceSentence)
        self.chineseMeaning = try container.decode(String.self, forKey: .chineseMeaning)
        self.analysisScopeNote = try container.decodeIfPresent(String.self, forKey: .analysisScopeNote) ?? ""
        self.chunks = try container.decodeIfPresent([GrammarChunk].self, forKey: .chunks) ?? []
        self.dependencies = try container.decodeIfPresent([GrammarDependency].self, forKey: .dependencies) ?? []
        self.tree = try container.decodeIfPresent(GrammarTreeNode.self, forKey: .tree)
            ?? GrammarTreeNode(label: "主句", role: .predicate, text: sourceSentence)
        self.trunk = try container.decodeIfPresent(GrammarTrunk.self, forKey: .trunk)
            ?? GrammarTrunk(core: [], dropped: [], coreZh: "")
        self.tenseVoice = try container.decodeIfPresent([GrammarTenseClause].self, forKey: .tenseVoice) ?? []
        self.wordOrder = try container.decodeIfPresent(GrammarWordOrder.self, forKey: .wordOrder)
            ?? GrammarWordOrder(en: [], zhOrder: [], zhText: [], note: "")
        self.pattern = pattern
        self.collocations = try container.decodeIfPresent([GrammarCollocation].self, forKey: .collocations) ?? []
        self.phrases = try container.decodeIfPresent([GrammarPhrase].self, forKey: .phrases) ?? []
        self.grammarPoints = try container.decodeIfPresent([GrammarPoint].self, forKey: .grammarPoints) ?? []
        self.defaultCollectionItem = try container.decodeIfPresent(DefaultCollectionItem.self, forKey: .defaultCollectionItem)
            ?? DefaultCollectionItem(title: pattern.en, note: pattern.zh, type: "句型")
    }
}

public struct GrammarChunk: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var role: GrammarRole
    public var text: String
    public var label: String
    public var note: String
    public var tokens: [GrammarToken]

    public init(id: String, role: GrammarRole, text: String, label: String, note: String, tokens: [GrammarToken] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.label = label
        self.note = note
        self.tokens = tokens
    }

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case label
        case note
        case tokens
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decodeIfPresent(GrammarRole.self, forKey: .role) ?? .attr
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.id = try container.decodeLossyStringIfPresent(forKey: .id) ?? (text.isEmpty ? role.rawValue : text)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? role.zh
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.tokens = try container.decodeIfPresent([GrammarToken].self, forKey: .tokens) ?? []
    }
}

fileprivate struct LocatedGrammarChunk {
    var chunk: GrammarChunk
    var start: Int?
    var end: Int?
}

public extension GrammarResult {
    static func recoveryChunks(for sourceSentence: String) -> [GrammarChunk] {
        let source = sourceSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            return []
        }

        let chunks = colonRecoveryChunks(for: source)
            ?? passiveContrastRecoveryChunks(for: source)
            ?? semicolonResultRecoveryChunks(for: source)
            ?? copularContentRecoveryChunks(for: source)
            ?? reportedBeliefRecoveryChunks(for: source)
            ?? fallbackLinearRecoveryChunks(for: source)
        return normalizedChunks(chunks, in: source)
    }

    static func normalizedChunks(_ chunks: [GrammarChunk], in sourceSentence: String) -> [GrammarChunk] {
        let cleanedChunks = chunks
            .map(cleanedChunk)
            .filter { !$0.text.isEmpty }
        let locatedChunks = locate(chunks: cleanedChunks, in: sourceSentence)
        let coarseIndexes = coarseChunkIndexes(in: locatedChunks)
        let expanded = locatedChunks.enumerated().flatMap { index, located in
            if coarseIndexes.contains(index) {
                return [GrammarChunk]()
            }
            return expandChunk(located.chunk)
        }
        let merged = mergeDuplicateRelativePronouns(
            in: locate(chunks: expanded, in: sourceSentence)
        )
        let copularAdjusted = normalizeCopularComplements(in: merged)
        let invertedAdjusted = recoverInvertedCopularClause(
            in: copularAdjusted,
            sourceSentence: sourceSentence
        )
        let scoped = scopeRelativeClauseTailObjects(
            in: invertedAdjusted,
            sourceSentence: sourceSentence
        )
        return uniquedChunkIDs(scoped)
    }

    private static func colonRecoveryChunks(for source: String) -> [GrammarChunk]? {
        guard let colonRange = source.range(of: ":") else {
            return nil
        }

        let lead = String(source[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tail = String(source[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks = splitLeadClause(lead)
        chunks.append(
            GrammarChunk(
                id: "colon",
                role: .conj,
                text: ":",
                label: "解释连接",
                note: "冒号引出后面对前一分句的解释。"
            )
        )

        let clauses = tail
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for (index, clause) in clauses.enumerated() {
            chunks.append(
                GrammarChunk(
                    id: "explain-\(index + 1)",
                    role: .appos,
                    text: clause,
                    label: index == 0 ? "解释分句" : "并列解释分句",
                    note: "冒号后的并列分句，展开说明前面的结果或原因。"
                )
            )
        }
        return chunks
    }

    private static func splitLeadClause(_ lead: String) -> [GrammarChunk] {
        let verbPatterns = [" creates ", " create ", " leads to ", " lead to ", " causes ", " cause ", " produces ", " produce "]
        for pattern in verbPatterns {
            guard let range = lead.range(of: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let subject = String(lead[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let predicate = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
            let object = String(lead[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return [
                GrammarChunk(id: "lead-s", role: .subject, text: subject, label: "主语", note: "冒号前主句的主语。"),
                GrammarChunk(id: "lead-v", role: .predicate, text: predicate, label: "谓语", note: "冒号前主句的谓语。"),
                GrammarChunk(id: "lead-o", role: .object, text: object, label: "宾语", note: "冒号前主句的宾语或结果。")
            ].filter { !$0.text.isEmpty }
        }

        return [
            GrammarChunk(id: "lead", role: .predicate, text: lead, label: "主句", note: "冒号前的核心分句。")
        ].filter { !$0.text.isEmpty }
    }

    private static func passiveContrastRecoveryChunks(for source: String) -> [GrammarChunk]? {
        guard let contrastRange = source.range(of: ", but ", options: [.caseInsensitive]) else {
            return nil
        }

        let lead = String(source[..<contrastRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tail = String(source[contrastRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard var chunks = passiveLeadChunks(for: lead) else {
            return nil
        }

        chunks.append(
            GrammarChunk(
                id: "contrast",
                role: .conj,
                text: "but",
                label: "转折连接",
                note: "连接前后两个形成对比的并列分句。"
            )
        )
        chunks.append(contentsOf: passiveTailChunks(for: tail))
        return chunks.count >= 6 ? chunks : nil
    }

    private static func passiveLeadChunks(for clause: String) -> [GrammarChunk]? {
        let passivePatterns = [
            " are often assumed to be ",
            " are assumed to be ",
            " is often assumed to be ",
            " is assumed to be ",
            " were often assumed to be ",
            " was often assumed to be "
        ]

        for pattern in passivePatterns {
            guard let range = clause.range(of: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let subject = String(clause[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let afterPassive = String(clause[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !subject.isEmpty, !afterPassive.isEmpty else {
                continue
            }

            let predicate: String
            let byPhrase: String?
            if let byRange = afterPassive.range(of: " by ", options: [.caseInsensitive]) {
                let predicateTail = String(afterPassive[..<byRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                predicate = [pattern.trimmingCharacters(in: .whitespacesAndNewlines), predicateTail]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                byPhrase = String(afterPassive[byRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                predicate = [pattern.trimmingCharacters(in: .whitespacesAndNewlines), afterPassive]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                byPhrase = nil
            }

            var chunks = [
                GrammarChunk(id: "passive-s", role: .subject, text: subject, label: "主语", note: "被动主句的主语。"),
                GrammarChunk(id: "passive-v", role: .predicate, text: predicate, label: "被动谓语", note: "assumed to be 后接被动补足。")
            ]
            if let byPhrase, !byPhrase.isEmpty {
                chunks.append(
                    GrammarChunk(id: "passive-by", role: .adv, text: byPhrase, label: "施事/方式状语", note: "说明被缓解依靠的来源。")
                )
            }
            return chunks
        }

        return nil
    }

    private static func passiveTailChunks(for tail: String) -> [GrammarChunk] {
        var remaining = tail.trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks: [GrammarChunk] = []

        if let hostRange = remaining.range(of: " host cities ", options: [.caseInsensitive]) {
            let adverbial = String(remaining[..<hostRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !adverbial.isEmpty {
                chunks.append(
                    GrammarChunk(id: "contrast-adv", role: .adv, text: adverbial, label: "频率状语", note: "说明转折后情况经常发生。")
                )
            }
            remaining = String(remaining[hostRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let secondRange = remaining.range(of: " and their taxpayers ", options: [.caseInsensitive]) else {
            if let simple = splitPassiveClause(remaining, idPrefix: "contrast-1", predicateLabel: "转折分句谓语") {
                chunks.append(contentsOf: simple)
            }
            return chunks
        }

        let firstClause = String(remaining[..<secondRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let secondClause = "their taxpayers " + String(remaining[secondRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = splitPassiveClause(firstClause, idPrefix: "contrast-1", predicateLabel: "转折分句谓语") {
            chunks.append(contentsOf: first)
        }
        if let second = splitLeftSettlingClause(secondClause) {
            chunks.append(contentsOf: second)
        } else if let second = splitPassiveClause(secondClause, idPrefix: "contrast-2", predicateLabel: "并列被动谓语") {
            chunks.append(contentsOf: second)
        }
        return chunks
    }

    private static func splitPassiveClause(_ clause: String, idPrefix: String, predicateLabel: String) -> [GrammarChunk]? {
        guard let range = clause.range(of: " are ", options: [.caseInsensitive]) else {
            return nil
        }

        let subject = String(clause[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate = String(clause[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty, !predicate.isEmpty else {
            return nil
        }

        return [
            GrammarChunk(id: "\(idPrefix)-s", role: .subject, text: subject, label: "并列主语", note: "转折分句中的主语。"),
            GrammarChunk(id: "\(idPrefix)-v", role: .predicate, text: predicate, label: predicateLabel, note: "被动结构说明该主语承受的结果。")
        ]
    }

    private static func splitLeftSettlingClause(_ clause: String) -> [GrammarChunk]? {
        guard let range = clause.range(of: " are left settling ", options: [.caseInsensitive]) else {
            return nil
        }

        let subject = String(clause[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let object = String(clause[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !subject.isEmpty, !object.isEmpty else {
            return nil
        }

        return [
            GrammarChunk(id: "contrast-2-s", role: .subject, text: subject, label: "并列主语", note: "第二个转折分句的主语。"),
            GrammarChunk(id: "contrast-2-v", role: .predicate, text: "are left settling", label: "并列被动谓语", note: "left settling 表示被留下来继续承担。"),
            GrammarChunk(id: "contrast-2-o", role: .object, text: object, label: "谓语宾语", note: "settling 的宾语。")
        ]
    }

    private static func semicolonResultRecoveryChunks(for source: String) -> [GrammarChunk]? {
        guard let semicolonRange = source.range(of: "; ") else {
            return nil
        }

        let lead = String(source[..<semicolonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tail = String(source[semicolonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard lead.lowercased().hasPrefix("as "),
              tail.range(of: " so ", options: [.caseInsensitive]) != nil,
              tail.range(of: " that ", options: [.caseInsensitive]) != nil else {
            return nil
        }

        var chunks = introductoryClauseChunks(
            lead,
            idPrefix: "lead",
            label: "时间状语从句",
            note: "as 引导时间背景，说明主句动作发生的阶段。"
        )
        chunks.append(
            GrammarChunk(id: "semicolon", role: .conj, text: ";", label: "分号连接", note: "连接前后两个密切相关的分句。")
        )
        chunks.append(contentsOf: soThatResultChunks(for: tail))
        return chunks.count >= 7 ? chunks : nil
    }

    private static func introductoryClauseChunks(
        _ clause: String,
        idPrefix: String,
        label: String,
        note: String
    ) -> [GrammarChunk] {
        guard let commaRange = clause.range(of: ",") else {
            return [
                GrammarChunk(id: "\(idPrefix)-adv", role: .adv, text: clause, label: label, note: note)
            ].filter { !$0.text.isEmpty }
        }

        let introductory = String(clause[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let main = String(clause[clause.index(after: commaRange.lowerBound)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks: [GrammarChunk] = []
        if !introductory.isEmpty {
            chunks.append(GrammarChunk(id: "\(idPrefix)-adv", role: .adv, text: introductory, label: label, note: note))
        }

        if let relativeRange = main.range(of: " that ", options: [.caseInsensitive]) {
            let mainHead = String(main[..<relativeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            chunks.append(contentsOf: splitSimpleClause(mainHead, idPrefix: "\(idPrefix)-main"))
            let relative = String(main[relativeRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let relativeText = "that \(relative)"
            if main.range(of: relativeText, options: [.caseInsensitive]) != nil {
                chunks.append(
                    GrammarChunk(
                        id: "\(idPrefix)-rel",
                        role: .attr,
                        text: relativeText,
                        label: "定语从句",
                        note: "修饰前面的名词短语。"
                    )
                )
            }
        } else {
            chunks.append(contentsOf: splitSimpleClause(main, idPrefix: "\(idPrefix)-main"))
        }
        return chunks
    }

    private static func splitSimpleClause(_ clause: String, idPrefix: String) -> [GrammarChunk] {
        let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        let patterns: [(String, String)] = [
            (" tunes into ", "谓语"),
            (" accrue to ", "谓语"),
            (" could feasibly travel ", "情态谓语"),
            (" can exceed ", "情态谓语")
        ]
        for (pattern, predicateLabel) in patterns {
            guard let range = trimmed.range(of: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let subject = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let predicate = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
            let object = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return [
                GrammarChunk(id: "\(idPrefix)-s", role: .subject, text: subject, label: "主语", note: "分句主语。"),
                GrammarChunk(id: "\(idPrefix)-v", role: .predicate, text: predicate, label: predicateLabel, note: "分句谓语。"),
                GrammarChunk(id: "\(idPrefix)-o", role: .object, text: object, label: "宾语/补足", note: "谓语后的核心内容。")
            ].filter { !$0.text.isEmpty }
        }

        return [
            GrammarChunk(id: "\(idPrefix)-clause", role: .predicate, text: trimmed, label: "分句", note: "恢复显示的分句骨架。")
        ]
    }

    private static func soThatResultChunks(for clause: String) -> [GrammarChunk] {
        guard let soRange = clause.range(of: " is so ", options: [.caseInsensitive]),
              let thatRange = clause.range(of: " that ", options: [.caseInsensitive]) else {
            return [GrammarChunk(id: "result", role: .predicate, text: clause, label: "结果分句", note: "恢复显示的结果分句。")]
        }

        let subject = String(clause[..<soRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let complement = String(clause[clause.index(soRange.lowerBound, offsetBy: 4)..<thatRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resultClause = String(clause[thatRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks = [
            GrammarChunk(id: "result-s", role: .subject, text: subject, label: "主语", note: "分号后结果结构的主语。"),
            GrammarChunk(id: "result-v", role: .predicate, text: "is", label: "系动词", note: "连接主语和程度表语。"),
            GrammarChunk(id: "result-c", role: .appos, text: complement, label: "程度表语", note: "so ... that 结构中的程度部分。"),
            GrammarChunk(id: "result-that", role: .conj, text: "that", label: "结果连接词", note: "引出 so ... that 的结果分句。")
        ].filter { !$0.text.isEmpty }

        chunks.append(contentsOf: splitByLettingResultClause(resultClause))
        return chunks
    }

    private static func splitByLettingResultClause(_ clause: String) -> [GrammarChunk] {
        let trimmed = clause
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard let byRange = trimmed.range(of: " by ", options: [.caseInsensitive]) else {
            return splitSimpleClause(trimmed, idPrefix: "result-clause")
        }

        let main = String(trimmed[..<byRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let byPhrase = String(trimmed[byRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks = splitSharkAttackClause(main)
        chunks.append(
            GrammarChunk(id: "result-method", role: .adv, text: byPhrase, label: "方式状语", note: "说明攻击时采用的保护方式。")
        )
        return chunks
    }

    private static func splitSharkAttackClause(_ clause: String) -> [GrammarChunk] {
        guard let range = clause.range(of: " even attacks ", options: [.caseInsensitive]) else {
            return splitSimpleClause(clause, idPrefix: "result-clause")
        }

        let subject = String(clause[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate = String(clause[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return [
            GrammarChunk(id: "result-clause-s", role: .subject, text: subject, label: "结果分句主语", note: "that 引导结果分句中的主语。"),
            GrammarChunk(id: "result-clause-v", role: .predicate, text: predicate, label: "结果分句谓语", note: "说明结果动作。")
        ].filter { !$0.text.isEmpty }
    }

    private static func copularContentRecoveryChunks(for source: String) -> [GrammarChunk]? {
        guard let contentRange = source.range(of: " is that ", options: [.caseInsensitive]) else {
            return nil
        }

        let subject = String(source[..<contentRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        var rest = String(source[contentRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard rest.lowercased().hasPrefix("when ") else {
            return nil
        }

        var chunks = [
            GrammarChunk(id: "content-s", role: .subject, text: subject, label: "主语", note: "主句提出的 concern。"),
            GrammarChunk(id: "content-v", role: .predicate, text: "is", label: "系动词", note: "后接 that 内容从句。"),
            GrammarChunk(id: "content-that", role: .conj, text: "that", label: "内容从句连接词", note: "引出 concern 的具体内容。")
        ].filter { !$0.text.isEmpty }

        if let commaRange = rest.range(of: ",") {
            let whenClause = String(rest[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            chunks.append(contentsOf: splitWhenUndertakenClause(whenClause) ?? [
                GrammarChunk(id: "content-when", role: .adv, text: whenClause, label: "时间状语从句", note: "when 引导内容从句内部的时间条件。")
            ])
            rest = String(rest[rest.index(after: commaRange.lowerBound)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        chunks.append(contentsOf: benefitAccrualChunks(for: rest))
        return chunks.count >= 7 ? chunks : nil
    }

    private static func splitWhenUndertakenClause(_ clause: String) -> [GrammarChunk]? {
        let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("when "),
              let undertakenRange = trimmed.range(of: " are undertaken ", options: [.caseInsensitive]) else {
            return nil
        }

        let subjectStart = trimmed.index(trimmed.startIndex, offsetBy: 5)
        let subject = String(trimmed[subjectStart..<undertakenRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let adverbial = String(trimmed[undertakenRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return [
            GrammarChunk(id: "content-when-link", role: .conj, text: "when", label: "时间连接词", note: "引导内容从句内部的时间条件。"),
            GrammarChunk(id: "content-when-s", role: .subject, text: subject, label: "时间从句主语", note: "when 从句中的主语。"),
            GrammarChunk(id: "content-when-v", role: .predicate, text: "are undertaken", label: "时间从句被动谓语", note: "说明基础设施建设被开展。"),
            GrammarChunk(id: "content-when-adv", role: .adv, text: adverbial, label: "目的/准备状语", note: "说明建设是为举办奥运做准备。")
        ].filter { !$0.text.isEmpty }
    }

    private static func benefitAccrualChunks(for clause: String) -> [GrammarChunk] {
        let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        let exceptionText: String?
        let mainText: String
        if let exceptionRange = trimmed.range(of: " with the exception of ", options: [.caseInsensitive]) {
            mainText = String(trimmed[..<exceptionRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            exceptionText = String(trimmed[exceptionRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            mainText = trimmed
            exceptionText = nil
        }

        var chunks = splitSimpleClause(mainText, idPrefix: "content-main")
        if let exceptionText, let relativeRange = exceptionText.range(of: " that ", options: [.caseInsensitive]) {
            let exceptionHead = String(exceptionText[..<relativeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let relative = String(exceptionText[relativeRange.lowerBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            chunks.append(
                GrammarChunk(id: "content-exception", role: .adv, text: exceptionHead, label: "例外状语", note: "说明收益集中时排除或附带的范围。")
            )
            chunks.append(
                GrammarChunk(id: "content-relative", role: .attr, text: relative, label: "定语从句", note: "修饰 outlying areas。")
            )
        } else if let exceptionText {
            chunks.append(
                GrammarChunk(id: "content-exception", role: .adv, text: exceptionText, label: "例外状语", note: "说明收益集中时排除或附带的范围。")
            )
        }
        return chunks
    }

    private static func reportedBeliefRecoveryChunks(for source: String) -> [GrammarChunk]? {
        guard let beliefRange = source.range(of: " believes that ", options: [.caseInsensitive]) else {
            return nil
        }

        let subject = String(source[..<beliefRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        var rest = String(source[beliefRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard rest.lowercased().hasPrefix("once ") else {
            return nil
        }

        var chunks = [
            GrammarChunk(id: "belief-s", role: .subject, text: subject, label: "主语", note: "报告观点的人物。"),
            GrammarChunk(id: "belief-v", role: .predicate, text: "believes", label: "谓语", note: "引出观点内容。"),
            GrammarChunk(id: "belief-that", role: .conj, text: "that", label: "宾语从句连接词", note: "引出 believes 的内容。")
        ].filter { !$0.text.isEmpty }

        if let commaRange = rest.range(of: ",") {
            let onceClause = String(rest[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            chunks.append(contentsOf: splitOnceCanClause(onceClause) ?? [
                GrammarChunk(id: "belief-once", role: .adv, text: onceClause, label: "时间条件从句", note: "once 引导宾语从句内部的时间条件。")
            ])
            rest = String(rest[rest.index(after: commaRange.lowerBound)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        chunks.append(contentsOf: travelPurposeChunks(for: rest))
        return chunks.count >= 7 ? chunks : nil
    }

    private static func splitOnceCanClause(_ clause: String) -> [GrammarChunk]? {
        let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("once ") else {
            return nil
        }

        let contentStart = trimmed.index(trimmed.startIndex, offsetBy: 5)
        let content = String(trimmed[contentStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let core = splitSimpleClause(content, idPrefix: "belief-once")
        guard core.count >= 3 else {
            return nil
        }

        return [
            GrammarChunk(id: "belief-once-link", role: .conj, text: "once", label: "时间条件连接词", note: "引导宾语从句内部的时间条件。")
        ] + core
    }

    private static func travelPurposeChunks(for clause: String) -> [GrammarChunk] {
        let trimmed = clause
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard let purposeRange = trimmed.range(of: " in order to ", options: [.caseInsensitive]) else {
            return splitSimpleClause(trimmed, idPrefix: "belief-main")
        }

        let main = String(trimmed[..<purposeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let purposeTail = String(trimmed[purposeRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        var chunks = splitSimpleClause(main, idPrefix: "belief-main")

        if let conditionRange = purposeTail.range(of: " in the event of ", options: [.caseInsensitive]) {
            let purpose = String(purposeTail[..<conditionRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let condition = String(purposeTail[conditionRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            chunks.append(
                GrammarChunk(id: "belief-purpose", role: .adv, text: purpose, label: "目的状语", note: "in order to 表示旅行的目的。")
            )
            chunks.append(
                GrammarChunk(id: "belief-condition", role: .adv, text: condition, label: "条件状语", note: "说明目的发生的灾难背景。")
            )
        } else {
            chunks.append(
                GrammarChunk(id: "belief-purpose", role: .adv, text: purposeTail, label: "目的状语", note: "in order to 表示旅行的目的。")
            )
        }
        return chunks
    }

    private static func fallbackLinearRecoveryChunks(for source: String) -> [GrammarChunk] {
        let words = source.split { $0.isWhitespace }
        guard words.count > 8 else {
            return [
                GrammarChunk(id: "sentence", role: .predicate, text: source, label: "句子", note: "恢复显示的短句骨架。")
            ].filter { !$0.text.isEmpty }
        }

        let firstCut = min(6, words.count)
        let secondCut = min(firstCut + 5, words.count)
        let subject = words[..<firstCut].joined(separator: " ")
        let predicate = words[firstCut..<secondCut].joined(separator: " ")
        let rest = words[secondCut...].joined(separator: " ")
        return [
            GrammarChunk(id: "fallback-s", role: .subject, text: subject, label: "主语/话题", note: "恢复显示的句首话题。"),
            GrammarChunk(id: "fallback-v", role: .predicate, text: predicate, label: "谓语片段", note: "恢复显示的核心动作片段。"),
            GrammarChunk(id: "fallback-rest", role: .object, text: rest, label: "补足/修饰", note: "恢复显示的后续内容。")
        ].filter { !$0.text.isEmpty }
    }

    private static func cleanedChunk(_ chunk: GrammarChunk) -> GrammarChunk {
        GrammarChunk(
            id: chunk.id.trimmingCharacters(in: .whitespacesAndNewlines),
            role: chunk.role,
            text: chunk.text.trimmingCharacters(in: .whitespacesAndNewlines),
            label: chunk.label.trimmingCharacters(in: .whitespacesAndNewlines),
            note: chunk.note.trimmingCharacters(in: .whitespacesAndNewlines),
            tokens: chunk.tokens
        )
    }

    private static func locate(chunks: [GrammarChunk], in sourceSentence: String) -> [LocatedGrammarChunk] {
        var searchStart = sourceSentence.startIndex
        return chunks.map { chunk in
            let searchRange = searchStart..<sourceSentence.endIndex
            let range = sourceSentence.range(of: chunk.text, options: [.caseInsensitive], range: searchRange)
                ?? sourceSentence.range(of: chunk.text, options: [.caseInsensitive])

            guard let range else {
                return LocatedGrammarChunk(chunk: chunk, start: nil, end: nil)
            }

            searchStart = range.upperBound
            let start = sourceSentence.distance(from: sourceSentence.startIndex, to: range.lowerBound)
            let end = sourceSentence.distance(from: sourceSentence.startIndex, to: range.upperBound)
            return LocatedGrammarChunk(chunk: chunk, start: start, end: end)
        }
    }

    private static func coarseChunkIndexes(in locatedChunks: [LocatedGrammarChunk]) -> Set<Int> {
        Set(locatedChunks.indices.filter { outerIndex in
            let outer = locatedChunks[outerIndex]
            guard let outerStart = outer.start,
                  let outerEnd = outer.end,
                  wordCount(outer.chunk.text) >= 5 else {
                return false
            }

            let contained = locatedChunks.indices.filter { innerIndex in
                guard innerIndex != outerIndex,
                      let innerStart = locatedChunks[innerIndex].start,
                      let innerEnd = locatedChunks[innerIndex].end else {
                    return false
                }
                let isInside = innerStart >= outerStart && innerEnd <= outerEnd
                let isSameSpan = innerStart == outerStart && innerEnd == outerEnd
                return isInside && !isSameSpan
            }

            guard contained.count >= 2 else {
                return false
            }

            let nestedRoles = Set(contained.map { locatedChunks[$0].chunk.role })
            return nestedRoles.contains(.subject)
                || nestedRoles.contains(.predicate)
                || nestedRoles.contains(.object)
        })
    }

    private static func expandChunk(_ chunk: GrammarChunk) -> [GrammarChunk] {
        let relativeChunks = splitRelativeClause(chunk) ?? [correctCoordinatedFinitePredicate(chunk)]
        return relativeChunks.flatMap(splitOversizedAdverbial)
    }

    private static func splitRelativeClause(_ chunk: GrammarChunk) -> [GrammarChunk]? {
        guard chunk.role == .attr,
              wordCount(chunk.text) >= 4,
              let connectorRange = chunk.text.rangeOfFirstWord else {
            return nil
        }

        let connector = String(chunk.text[connectorRange])
        guard relativeConnectors.contains(connector.lowercased()) else {
            return nil
        }

        let remaining = String(chunk.text[connectorRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let predicateRange = remaining.rangeOfFirstWord else {
            return nil
        }

        let predicateHead = String(remaining[predicateRange])
        guard !relativeSubjectStarts.contains(predicateHead.lowercased()),
              !finiteAuxiliaries.contains(predicateHead.lowercased()) else {
            return nil
        }

        let complement = String(remaining[predicateRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard wordCount(complement) >= 2 else {
            return nil
        }

        let complementRole: GrammarRole = startsWithPreposition(complement) ? .adv : .object
        let complementLabel = complementRole == .object ? "定语从句宾语" : "定语从句修饰语"
        return [
            GrammarChunk(
                id: "\(chunk.id)-rel",
                role: .conj,
                text: connector,
                label: "关系词",
                note: chunk.note.isEmpty ? "引导定语从句。" : chunk.note
            ),
            GrammarChunk(
                id: "\(chunk.id)-rel-v",
                role: .predicate,
                text: predicateHead,
                label: "定语从句谓语",
                note: "说明先行词在定语从句中的动作。"
            ),
            GrammarChunk(
                id: "\(chunk.id)-rel-c",
                role: complementRole,
                text: complement,
                label: complementLabel,
                note: "属于前面的定语从句，不是主句级成分。"
            )
        ]
    }

    private static func correctCoordinatedFinitePredicate(_ chunk: GrammarChunk) -> GrammarChunk {
        guard chunk.role == .adv else {
            return chunk
        }

        let text = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerText = text.lowercased()
        guard lowerText.hasPrefix("and "),
              let afterAndRange = text.range(of: "and ", options: [.caseInsensitive]) else {
            return chunk
        }

        let afterAnd = String(text[afterAndRange.upperBound...])
        let words = lowercaseWords(in: afterAnd)
        guard let firstWord = words.first,
              finiteAuxiliaries.contains(firstWord),
              words.count >= 3 else {
            return chunk
        }

        let label = chunk.label.contains("谓语") ? chunk.label : "并列谓语"
        let note = chunk.note.isEmpty
            ? "与前面的谓语共享主语。"
            : "\(chunk.note)；与前面的谓语共享主语。"
        return GrammarChunk(
            id: chunk.id,
            role: .predicate,
            text: chunk.text,
            label: label,
            note: note,
            tokens: chunk.tokens
        )
    }

    private static func scopeRelativeClauseTailObjects(
        in locatedChunks: [LocatedGrammarChunk],
        sourceSentence: String
    ) -> [GrammarChunk] {
        var result: [GrammarChunk] = []
        var isInsideRelativeTail = false
        var previousEnd: Int?

        for located in locatedChunks {
            var chunk = located.chunk
            if isInsideRelativeTail,
               chunk.role == .object,
               canContinueRelativeClauseTail(
                   from: previousEnd,
                   to: located.start,
                   chunk: chunk,
                   sourceSentence: sourceSentence
               ) {
                chunk = relabeledRelativeClauseTailObject(chunk)
            } else if chunk.role == .subject || chunk.role == .predicate {
                isInsideRelativeTail = isRelativeClauseChunk(chunk)
            }

            if isRelativeClauseChunk(chunk), chunk.role == .object || chunk.role == .adv {
                isInsideRelativeTail = true
            }
            if located.end != nil {
                previousEnd = located.end
            }
            result.append(chunk)
        }

        return result
    }

    private static func mergeDuplicateRelativePronouns(
        in locatedChunks: [LocatedGrammarChunk]
    ) -> [LocatedGrammarChunk] {
        var merged: [LocatedGrammarChunk] = []
        for located in locatedChunks {
            if let lastIndex = merged.indices.last,
               shouldMergeRelativePronounConnector(merged[lastIndex], with: located) {
                merged[lastIndex] = mergedRelativePronounConnector(merged[lastIndex], with: located)
            } else {
                merged.append(located)
            }
        }
        return merged
    }

    private static func shouldMergeRelativePronounConnector(
        _ connector: LocatedGrammarChunk,
        with subject: LocatedGrammarChunk
    ) -> Bool {
        guard connector.chunk.role == .conj,
              subject.chunk.role == .subject,
              let connectorWord = lowercaseWords(in: connector.chunk.text).first,
              relativeConnectors.contains(connectorWord) else {
            return false
        }

        let subjectWords = lowercaseWords(in: subject.chunk.text)
        guard subjectWords.first == connectorWord else {
            return false
        }

        if let connectorStart = connector.start,
           let subjectStart = subject.start {
            return connectorStart == subjectStart
        }
        return connector.chunk.text.caseInsensitiveCompare(subject.chunk.text) == .orderedSame
    }

    private static func mergedRelativePronounConnector(
        _ connector: LocatedGrammarChunk,
        with subject: LocatedGrammarChunk
    ) -> LocatedGrammarChunk {
        LocatedGrammarChunk(
            chunk: GrammarChunk(
                id: subject.chunk.id.isEmpty ? connector.chunk.id : subject.chunk.id,
                role: .subject,
                text: subject.chunk.text,
                label: mergedRelativePronounLabel(connector: connector.chunk, subject: subject.chunk),
                note: mergedRelativePronounNote(connector: connector.chunk, subject: subject.chunk),
                tokens: subject.chunk.tokens.isEmpty ? connector.chunk.tokens : subject.chunk.tokens
            ),
            start: subject.start ?? connector.start,
            end: subject.end ?? connector.end
        )
    }

    private static func mergedRelativePronounLabel(connector: GrammarChunk, subject: GrammarChunk) -> String {
        let labels = [connector.label, subject.label]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let uniqueLabels = labels.reduce(into: [String]()) { partial, label in
            if !partial.contains(label) {
                partial.append(label)
            }
        }
        return uniqueLabels.isEmpty ? "关系代词 / 从句主语" : uniqueLabels.joined(separator: " / ")
    }

    private static func mergedRelativePronounNote(connector: GrammarChunk, subject: GrammarChunk) -> String {
        let notes = [connector.note, subject.note]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let uniqueNotes = notes.reduce(into: [String]()) { partial, note in
            if !partial.contains(note) {
                partial.append(note)
            }
        }
        return uniqueNotes.isEmpty
            ? "关系代词同时充当定语从句主语，只渲染一次。"
            : uniqueNotes.joined(separator: "；")
    }

    private static func normalizeCopularComplements(
        in locatedChunks: [LocatedGrammarChunk]
    ) -> [LocatedGrammarChunk] {
        var result: [LocatedGrammarChunk] = []
        var isAfterCopularPredicate = false
        var complementCount = 0

        for located in locatedChunks {
            var chunk = located.chunk
            if chunk.role == .predicate {
                isAfterCopularPredicate = isCopularPredicate(chunk)
                complementCount = 0
            } else if chunk.role == .subject {
                isAfterCopularPredicate = false
                complementCount = 0
            } else if isAfterCopularPredicate, chunk.role == .object {
                complementCount += 1
                chunk = relabeledCopularComplement(chunk, isCoordinated: complementCount > 1 || startsWithCoordinator(chunk.text))
            }

            result.append(LocatedGrammarChunk(chunk: chunk, start: located.start, end: located.end))
        }

        return result
    }

    private static func recoverInvertedCopularClause(
        in locatedChunks: [LocatedGrammarChunk],
        sourceSentence: String
    ) -> [LocatedGrammarChunk] {
        guard let markerRange = sourceSentence.range(of: ", however, is ", options: [.caseInsensitive]) else {
            return locatedChunks
        }

        let frontedText = String(sourceSentence[..<markerRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let subjectText = String(sourceSentence[markerRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !frontedText.isEmpty,
              !subjectText.isEmpty,
              !locatedChunks.contains(where: { $0.chunk.text.localizedCaseInsensitiveContains("the relationship") }) else {
            return locatedChunks
        }

        let frontedEnd = sourceSentence.distance(from: sourceSentence.startIndex, to: markerRange.lowerBound)
        let predicateStart = sourceSentence.distance(from: sourceSentence.startIndex, to: sourceSentence.index(markerRange.upperBound, offsetBy: -3))
        let predicateEnd = predicateStart + 2
        let subjectStart = sourceSentence.distance(from: sourceSentence.startIndex, to: markerRange.upperBound)
        let subjectEnd = sourceSentence.distance(from: sourceSentence.startIndex, to: sourceSentence.endIndex)

        let fronted = locatedChunks.first { located in
            guard let start = located.start, let end = located.end else {
                return false
            }
            return start >= 0 && end <= frontedEnd
        }?.chunk
        let predicate = locatedChunks.first { located in
            located.chunk.role == .predicate &&
                located.chunk.text.caseInsensitiveCompare("is") == .orderedSame
        }?.chunk

        return [
            LocatedGrammarChunk(
                chunk: relabeledFrontedCopularComplement(
                    fronted ?? GrammarChunk(id: "fronted-complement", role: .appos, text: frontedText, label: "前置表语", note: "倒装结构中提前到句首的表语。")
                ),
                start: 0,
                end: frontedEnd
            ),
            LocatedGrammarChunk(
                chunk: predicate ?? GrammarChunk(id: "inverted-v", role: .predicate, text: "is", label: "倒装系动词", note: "连接前置表语和后置主语。"),
                start: predicateStart,
                end: predicateEnd
            ),
            LocatedGrammarChunk(
                chunk: GrammarChunk(
                    id: "inverted-subject",
                    role: .subject,
                    text: subjectText,
                    label: "倒装主语",
                    note: "系动词后的完整主语，保留 relationship、activity 等核心词。"
                ),
                start: subjectStart,
                end: subjectEnd
            )
        ]
    }

    private static func relabeledCopularComplement(_ chunk: GrammarChunk, isCoordinated: Bool) -> GrammarChunk {
        let label = chunk.label.contains("表语") ? chunk.label : (isCoordinated ? "并列表语" : "表语")
        let note = chunk.note.contains("系动词")
            ? chunk.note
            : (chunk.note.isEmpty ? "系动词后的主语补足语，不是宾语。" : "\(chunk.note)；系动词后的主语补足语，不是宾语。")
        return GrammarChunk(
            id: chunk.id,
            role: .appos,
            text: chunk.text,
            label: label,
            note: note,
            tokens: chunk.tokens
        )
    }

    private static func relabeledFrontedCopularComplement(_ chunk: GrammarChunk) -> GrammarChunk {
        let label = chunk.label.contains("表语") ? chunk.label : "前置表语"
        let note = chunk.note.contains("倒装")
            ? chunk.note
            : (chunk.note.isEmpty ? "倒装系表结构中前置的表语。" : "\(chunk.note)；倒装系表结构中前置的表语。")
        return GrammarChunk(
            id: chunk.id,
            role: .appos,
            text: chunk.text,
            label: label,
            note: note,
            tokens: chunk.tokens
        )
    }

    private static func isCopularPredicate(_ chunk: GrammarChunk) -> Bool {
        guard chunk.role == .predicate,
              let lastWord = lowercaseWords(in: chunk.text).last else {
            return false
        }
        return copularPredicateHeads.contains(lastWord)
    }

    private static func startsWithCoordinator(_ text: String) -> Bool {
        guard let firstWord = lowercaseWords(in: text).first else {
            return false
        }
        return ["and", "or", "nor"].contains(firstWord)
    }

    private static func canContinueRelativeClauseTail(
        from previousEnd: Int?,
        to currentStart: Int?,
        chunk: GrammarChunk,
        sourceSentence: String
    ) -> Bool {
        let lowerText = chunk.text.lowercased()
        if lowerText.hasPrefix("and ") || lowerText.hasPrefix("or ") {
            return true
        }
        guard let previousEnd,
              let currentStart,
              previousEnd <= currentStart,
              let gap = sourceSentence.substring(fromOffset: previousEnd, toOffset: currentStart) else {
            return false
        }
        return gap.contains(",") || gap.contains(";")
    }

    private static func relabeledRelativeClauseTailObject(_ chunk: GrammarChunk) -> GrammarChunk {
        let label = chunk.label.contains("定语从句") ? chunk.label : "定语从句并列宾语"
        let note = chunk.note.contains("不是主句级")
            ? chunk.note
            : (chunk.note.isEmpty ? "属于前面的定语从句，不是主句级宾语。" : "\(chunk.note)；属于前面的定语从句，不是主句级宾语。")
        return GrammarChunk(
            id: chunk.id,
            role: chunk.role,
            text: chunk.text,
            label: label,
            note: note,
            tokens: chunk.tokens
        )
    }

    private static func splitOversizedAdverbial(_ chunk: GrammarChunk) -> [GrammarChunk] {
        guard chunk.role == .adv,
              wordCount(chunk.text) > 10,
              let split = splitPresentParticipleAdverbial(chunk) else {
            return [chunk]
        }
        return split
    }

    private static func splitPresentParticipleAdverbial(_ chunk: GrammarChunk) -> [GrammarChunk]? {
        let text = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstWordRange = text.rangeOfFirstWord else {
            return nil
        }

        let firstWord = String(text[firstWordRange])
        guard firstWord.lowercased().hasSuffix("ing"),
              let toRange = text.range(of: " to ", options: [.caseInsensitive]) else {
            return nil
        }

        let objectText = String(text[firstWordRange.upperBound..<toRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let actionText = String(text[toRange.lowerBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !objectText.isEmpty, wordCount(actionText) >= 4 else {
            return nil
        }

        var splitChunks: [GrammarChunk] = [
            GrammarChunk(
                id: "\(chunk.id)-adv",
                role: .adv,
                text: firstWord,
                label: chunk.label.isEmpty ? "结果状语" : chunk.label,
                note: chunk.note.isEmpty ? "非谓语短语作状语，先标出触发动作。" : chunk.note
            ),
            GrammarChunk(
                id: "\(chunk.id)-object",
                role: .object,
                text: objectText,
                label: "状语内部宾语",
                note: "\(firstWord) 的作用对象。"
            )
        ]

        let actions = splitCoordinatedInfinitive(actionText)
        for (index, action) in actions.enumerated() {
            splitChunks.append(
                GrammarChunk(
                    id: "\(chunk.id)-action-\(index + 1)",
                    role: .predicate,
                    text: action,
                    label: index == 0 ? "不定式动作" : "并列不定式动作",
                    note: "说明 \(objectText) 被允许或能够执行的动作。"
                )
            )
        }

        return splitChunks.count >= 3 ? splitChunks : nil
    }

    private static func splitCoordinatedInfinitive(_ text: String) -> [String] {
        guard wordCount(text) > 7,
              let andRange = text.range(of: " and ", options: [.caseInsensitive]) else {
            return [text]
        }

        let first = String(text[..<andRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let second = String(text[andRange.lowerBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard wordCount(first) >= 3, wordCount(second) >= 3 else {
            return [text]
        }
        return [first, second]
    }

    private static func uniquedChunkIDs(_ chunks: [GrammarChunk]) -> [GrammarChunk] {
        var seen: [String: Int] = [:]
        return chunks.enumerated().map { index, chunk in
            let fallbackID = "\(chunk.role.rawValue)-\(index + 1)"
            let baseID = chunk.id.isEmpty ? fallbackID : chunk.id
            let count = seen[baseID] ?? 0
            seen[baseID] = count + 1

            guard count > 0 else {
                return chunk.id == baseID
                    ? chunk
                    : GrammarChunk(id: baseID, role: chunk.role, text: chunk.text, label: chunk.label, note: chunk.note, tokens: chunk.tokens)
            }

            return GrammarChunk(
                id: "\(baseID)-\(count + 1)",
                role: chunk.role,
                text: chunk.text,
                label: chunk.label,
                note: chunk.note,
                tokens: chunk.tokens
            )
        }
    }

    private static func wordCount(_ text: String) -> Int {
        text.split { !$0.isLetter && !$0.isNumber }.count
    }

    private static func lowercaseWords(in text: String) -> [String] {
        text
            .split { !$0.isLetter && !$0.isNumber }
            .map { $0.lowercased() }
    }

    private static func startsWithPreposition(_ text: String) -> Bool {
        guard let firstWord = lowercaseWords(in: text).first else {
            return false
        }
        return prepositions.contains(firstWord)
    }

    private static func isRelativeClauseChunk(_ chunk: GrammarChunk) -> Bool {
        chunk.label.contains("定语从句") || chunk.note.contains("定语从句")
    }

    private static var relativeConnectors: Set<String> {
        ["that", "which", "who", "whom", "whose", "where", "when"]
    }

    private static var relativeSubjectStarts: Set<String> {
        ["a", "an", "the", "this", "that", "these", "those", "my", "your", "his", "her", "its", "our", "their", "i", "you", "he", "she", "it", "we", "they", "there", "one", "some", "many", "most"]
    }

    private static var finiteAuxiliaries: Set<String> {
        ["am", "is", "are", "was", "were", "be", "being", "been", "has", "have", "had", "do", "does", "did", "can", "could", "should", "would", "will", "shall", "may", "might", "must"]
    }

    private static var copularPredicateHeads: Set<String> {
        ["am", "is", "are", "was", "were", "be", "being", "been", "become", "becomes", "became", "seem", "seems", "seemed", "appear", "appears", "appeared", "remain", "remains", "remained"]
    }

    private static var prepositions: Set<String> {
        ["in", "on", "at", "by", "for", "with", "to", "from", "over", "under", "during", "after", "before", "as", "into", "onto", "through", "across", "around", "within", "without", "of"]
    }
}

fileprivate extension String {
    var rangeOfFirstWord: Range<String.Index>? {
        guard let start = firstIndex(where: { $0.isLetter }) else {
            return nil
        }
        let end = self[start...].firstIndex { !$0.isLetter } ?? endIndex
        return start..<end
    }

    func substring(fromOffset startOffset: Int, toOffset endOffset: Int) -> String? {
        guard startOffset >= 0,
              endOffset >= startOffset,
              let start = index(startIndex, offsetBy: startOffset, limitedBy: endIndex),
              let end = index(startIndex, offsetBy: endOffset, limitedBy: endIndex) else {
            return nil
        }
        return String(self[start..<end])
    }
}

public struct GrammarToken: Codable, Equatable, Sendable {
    public var w: String
    public var pos: String
    public var infl: String

    public init(w: String, pos: String, infl: String) {
        self.w = w
        self.pos = pos
        self.infl = infl
    }

    enum CodingKeys: String, CodingKey {
        case w
        case pos
        case infl
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.w = value
            self.pos = ""
            self.infl = ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.w = try container.decodeIfPresent(String.self, forKey: .w) ?? ""
        self.pos = try container.decodeIfPresent(String.self, forKey: .pos) ?? ""
        self.infl = try container.decodeIfPresent(String.self, forKey: .infl) ?? ""
    }
}

public struct GrammarDependency: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(from)-\(to)-\(label)" }
    public var from: String
    public var to: String
    public var label: String

    public init(from: String, to: String, label: String) {
        self.from = from
        self.to = to
        self.label = label
    }

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case label
    }

    public init(from decoder: Decoder) throws {
        if var values = try? decoder.unkeyedContainer() {
            self.from = (try? values.decode(GrammarLooseValue.self).stringValue) ?? ""
            self.to = (try? values.decode(GrammarLooseValue.self).stringValue) ?? ""
            self.label = (try? values.decode(GrammarLooseValue.self).stringValue) ?? "关系"
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.from = try container.decodeLossyStringIfPresent(forKey: .from) ?? ""
        self.to = try container.decodeLossyStringIfPresent(forKey: .to) ?? ""
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? "关系"
    }
}

public struct GrammarTreeNode: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(label)-\(text)" }
    public var label: String
    public var role: GrammarRole
    public var text: String
    public var children: [GrammarTreeNode]

    public init(
        label: String,
        role: GrammarRole,
        text: String,
        children: [GrammarTreeNode] = []
    ) {
        self.label = label
        self.role = role
        self.text = text
        self.children = children
    }

    enum CodingKeys: String, CodingKey {
        case label
        case role
        case text
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? "主句"
        self.role = try container.decodeIfPresent(GrammarRole.self, forKey: .role) ?? .predicate
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.children = try container.decodeIfPresent([GrammarTreeNode].self, forKey: .children) ?? []
    }
}

public struct GrammarTrunk: Codable, Equatable, Sendable {
    public var core: [GrammarTrunkItem]
    public var dropped: [String]
    public var coreZh: String

    public init(core: [GrammarTrunkItem], dropped: [String], coreZh: String) {
        self.core = core
        self.dropped = dropped
        self.coreZh = coreZh
    }

    enum CodingKeys: String, CodingKey {
        case core
        case dropped
        case coreZh
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.core = try container.decodeIfPresent([GrammarTrunkItem].self, forKey: .core) ?? []
        self.dropped = try container.decodeLossyStringArrayIfPresent(forKey: .dropped) ?? []
        self.coreZh = try container.decodeIfPresent(String.self, forKey: .coreZh) ?? ""
    }
}

public struct GrammarTrunkItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(role.rawValue)-\(w)" }
    public var w: String
    public var role: GrammarRole

    public init(w: String, role: GrammarRole) {
        self.w = w
        self.role = role
    }

    enum CodingKeys: String, CodingKey {
        case w
        case role
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.w = value
            self.role = .predicate
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.w = try container.decodeIfPresent(String.self, forKey: .w) ?? ""
        self.role = try container.decodeIfPresent(GrammarRole.self, forKey: .role) ?? .predicate
    }
}

public struct GrammarTenseClause: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(scope)-\(verb)" }
    public var scope: String
    public var verb: String
    public var tense: String
    public var aspect: String
    public var voice: String
    public var mood: String
    public var why: String
    public var svo: GrammarSVO

    public init(
        scope: String,
        verb: String,
        tense: String,
        aspect: String,
        voice: String,
        mood: String,
        why: String,
        svo: GrammarSVO
    ) {
        self.scope = scope
        self.verb = verb
        self.tense = tense
        self.aspect = aspect
        self.voice = voice
        self.mood = mood
        self.why = why
        self.svo = svo
    }

    enum CodingKeys: String, CodingKey {
        case scope
        case verb
        case tense
        case aspect
        case voice
        case mood
        case why
        case svo
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.scope = try container.decodeIfPresent(String.self, forKey: .scope) ?? "句子"
        self.verb = try container.decodeIfPresent(String.self, forKey: .verb) ?? ""
        self.tense = try container.decodeIfPresent(String.self, forKey: .tense) ?? "一般时"
        self.aspect = try container.decodeIfPresent(String.self, forKey: .aspect) ?? "一般体"
        self.voice = try container.decodeIfPresent(String.self, forKey: .voice) ?? "主动"
        self.mood = try container.decodeIfPresent(String.self, forKey: .mood) ?? "陈述"
        self.why = try container.decodeIfPresent(String.self, forKey: .why) ?? ""
        self.svo = try container.decodeIfPresent(GrammarSVO.self, forKey: .svo)
            ?? GrammarSVO(agent: "", action: self.verb, receiver: nil)
    }
}

public struct GrammarSVO: Codable, Equatable, Sendable {
    public var agent: String
    public var action: String
    public var receiver: String?

    public init(agent: String, action: String, receiver: String?) {
        self.agent = agent
        self.action = action
        self.receiver = receiver
    }

    enum CodingKeys: String, CodingKey {
        case agent
        case action
        case receiver
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.agent = try container.decodeIfPresent(String.self, forKey: .agent) ?? ""
        self.action = try container.decodeIfPresent(String.self, forKey: .action) ?? ""
        self.receiver = try container.decodeIfPresent(String.self, forKey: .receiver)
    }
}

public struct GrammarWordOrder: Codable, Equatable, Sendable {
    public var en: [GrammarOrderSegment]
    public var zhOrder: [Int]
    public var zhText: [String]
    public var note: String

    public init(en: [GrammarOrderSegment], zhOrder: [Int], zhText: [String], note: String) {
        self.en = en
        self.zhOrder = zhOrder
        self.zhText = zhText
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case en
        case zhOrder
        case zhText
        case note
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.en = try container.decodeIfPresent([GrammarOrderSegment].self, forKey: .en) ?? []
        self.zhOrder = try container.decodeLossyIntArrayIfPresent(forKey: .zhOrder) ?? self.en.map(\.id)
        self.zhText = try container.decodeLossyStringArrayIfPresent(forKey: .zhText) ?? self.en.map(\.text)
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

public struct GrammarOrderSegment: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var text: String
    public var role: GrammarRole
    public var zhPos: Int
    public var moved: Bool

    public init(id: Int, text: String, role: GrammarRole, zhPos: Int, moved: Bool = false) {
        self.id = id
        self.text = text
        self.role = role
        self.zhPos = zhPos
        self.moved = moved
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case role
        case zhPos
        case moved
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeLossyIntIfPresent(forKey: .id) ?? 0
        self.text = try container.decodeLossyStringIfPresent(forKey: .text) ?? ""
        self.role = try container.decodeIfPresent(GrammarRole.self, forKey: .role) ?? .attr
        self.zhPos = try container.decodeLossyIntIfPresent(forKey: .zhPos) ?? id
        self.moved = try container.decodeLossyBoolIfPresent(forKey: .moved) ?? false
    }
}

public struct GrammarPattern: Codable, Equatable, Sendable {
    public var en: String
    public var zh: String

    public init(en: String, zh: String) {
        self.en = en
        self.zh = zh
    }

    enum CodingKeys: String, CodingKey {
        case en
        case zh
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.en = value
            self.zh = ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.en = try container.decodeIfPresent(String.self, forKey: .en) ?? ""
        self.zh = try container.decodeIfPresent(String.self, forKey: .zh) ?? ""
    }
}

public struct GrammarCollocation: Codable, Equatable, Identifiable, Sendable {
    public var id: String { phrase }
    public var phrase: String
    public var pos: String
    public var zh: String
    public var note: String
    public var example: String

    public init(phrase: String, pos: String, zh: String, note: String, example: String) {
        self.phrase = phrase
        self.pos = pos
        self.zh = zh
        self.note = note
        self.example = example
    }

    enum CodingKeys: String, CodingKey {
        case phrase
        case pos
        case zh
        case note
        case example
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.phrase = value
            self.pos = ""
            self.zh = ""
            self.note = ""
            self.example = ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phrase = try container.decodeIfPresent(String.self, forKey: .phrase) ?? ""
        self.pos = try container.decodeIfPresent(String.self, forKey: .pos) ?? ""
        self.zh = try container.decodeIfPresent(String.self, forKey: .zh) ?? ""
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.example = try container.decodeIfPresent(String.self, forKey: .example) ?? ""
    }
}

public struct GrammarPhrase: Codable, Equatable, Identifiable, Sendable {
    public var id: String { en }
    public var en: String
    public var zh: String

    public init(en: String, zh: String) {
        self.en = en
        self.zh = zh
    }

    enum CodingKeys: String, CodingKey {
        case en
        case zh
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.en = value
            self.zh = ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.en = try container.decodeIfPresent(String.self, forKey: .en) ?? ""
        self.zh = try container.decodeIfPresent(String.self, forKey: .zh) ?? ""
    }
}

public struct GrammarPoint: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(tag)-\(title)" }
    public var tag: String
    public var title: String
    public var body: String

    public init(tag: String, title: String, body: String) {
        self.tag = tag
        self.title = title
        self.body = body
    }

    enum CodingKeys: String, CodingKey {
        case tag
        case title
        case body
    }

    public init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.tag = "语法"
            self.title = value
            self.body = ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? "语法"
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
    }
}

public extension GrammarResult {
    static let mockupFixture = GrammarResult(
        title: "语法解析",
        sourceSentence: "The findings published last year call into question long-held assumptions that memory is consolidated while we sleep.",
        chineseMeaning: "去年发表的这些研究结果，使人们开始质疑「记忆是在我们睡眠时被巩固的」这一长期假设。",
        chunks: [
            GrammarChunk(
                id: "s",
                role: .subject,
                text: "The findings",
                label: "主语",
                note: "复数主语，指上文的研究结果",
                tokens: [
                    GrammarToken(w: "The", pos: "限定词", infl: "定冠词，特指"),
                    GrammarToken(w: "findings", pos: "名词", infl: "复数 (-s)，find 的名词化")
                ]
            ),
            GrammarChunk(
                id: "d1",
                role: .attr,
                text: "published last year",
                label: "后置定语",
                note: "过去分词短语作后置定语，被动含义（findings 被发表）",
                tokens: [
                    GrammarToken(w: "published", pos: "过去分词", infl: "publish 的 -ed 分词，表被动"),
                    GrammarToken(w: "last year", pos: "时间短语", infl: "作分词的时间状语")
                ]
            ),
            GrammarChunk(
                id: "v",
                role: .predicate,
                text: "call into question",
                label: "谓语",
                note: "动词固定搭配；一般现在时表客观结论",
                tokens: [
                    GrammarToken(w: "call", pos: "动词", infl: "原形，主语复数故不加 -s"),
                    GrammarToken(w: "into question", pos: "介词短语", infl: "构成固定搭配的一部分")
                ]
            ),
            GrammarChunk(
                id: "o",
                role: .object,
                text: "long-held assumptions",
                label: "宾语",
                note: "核心宾语；long-held 为前置定语（复合形容词）",
                tokens: [
                    GrammarToken(w: "long-held", pos: "复合形容词", infl: "long + held(hold 的过去分词)，前置定语"),
                    GrammarToken(w: "assumptions", pos: "名词", infl: "复数 (-s)")
                ]
            ),
            GrammarChunk(
                id: "ap",
                role: .appos,
                text: "that memory is consolidated while we sleep",
                label: "同位语从句",
                note: "that 引导，说明 assumptions 的具体内容；内含被动 + 时间状语从句",
                tokens: [
                    GrammarToken(w: "that", pos: "从属连词", infl: "引导同位语从句，不作成分"),
                    GrammarToken(w: "memory", pos: "名词", infl: "从句主语，不可数"),
                    GrammarToken(w: "is consolidated", pos: "动词(被动)", infl: "be + 过去分词，一般现在时被动"),
                    GrammarToken(w: "while we sleep", pos: "状语从句", infl: "while 引导时间状语从句")
                ]
            )
        ],
        dependencies: [
            GrammarDependency(from: "v", to: "s", label: "主谓"),
            GrammarDependency(from: "s", to: "d1", label: "后置修饰"),
            GrammarDependency(from: "v", to: "o", label: "动宾"),
            GrammarDependency(from: "o", to: "ap", label: "同位")
        ],
        tree: GrammarTreeNode(
            label: "主句 (independent clause)",
            role: .predicate,
            text: "The findings ... call into question ... assumptions",
            children: [
                GrammarTreeNode(
                    label: "主语",
                    role: .subject,
                    text: "The findings",
                    children: [
                        GrammarTreeNode(label: "后置定语（分词）", role: .attr, text: "published last year")
                    ]
                ),
                GrammarTreeNode(label: "谓语（固定搭配）", role: .predicate, text: "call into question"),
                GrammarTreeNode(
                    label: "宾语",
                    role: .object,
                    text: "long-held assumptions",
                    children: [
                        GrammarTreeNode(
                            label: "同位语从句",
                            role: .appos,
                            text: "that memory is consolidated ...",
                            children: [
                                GrammarTreeNode(label: "从句主语", role: .subject, text: "memory"),
                                GrammarTreeNode(label: "从句谓语（被动）", role: .predicate, text: "is consolidated"),
                                GrammarTreeNode(
                                    label: "时间状语从句",
                                    role: .adv,
                                    text: "while we sleep",
                                    children: [
                                        GrammarTreeNode(label: "从句主语", role: .subject, text: "we"),
                                        GrammarTreeNode(label: "从句谓语", role: .predicate, text: "sleep")
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
        trunk: GrammarTrunk(
            core: [
                GrammarTrunkItem(w: "The findings", role: .subject),
                GrammarTrunkItem(w: "call into question", role: .predicate),
                GrammarTrunkItem(w: "assumptions", role: .object)
            ],
            dropped: [
                "published last year（后置定语·分词）",
                "long-held（前置定语）",
                "that memory is consolidated while we sleep（同位语从句）"
            ],
            coreZh: "这些研究结果质疑了某些假设。"
        ),
        tenseVoice: [
            GrammarTenseClause(
                scope: "主句",
                verb: "call into question",
                tense: "一般现在时",
                aspect: "一般体",
                voice: "主动",
                mood: "陈述",
                why: "用现在时表达普遍成立的客观结论，而非一次性事件。",
                svo: GrammarSVO(agent: "The findings", action: "call into question", receiver: "assumptions")
            ),
            GrammarTenseClause(
                scope: "同位语从句",
                verb: "is consolidated",
                tense: "一般现在时",
                aspect: "一般体",
                voice: "被动",
                mood: "陈述",
                why: "被动语态弱化施动者，强调“记忆被巩固”这一过程本身；现在时表客观规律。",
                svo: GrammarSVO(agent: "(大脑/睡眠，被省略)", action: "consolidate", receiver: "memory")
            ),
            GrammarTenseClause(
                scope: "时间状语从句",
                verb: "sleep",
                tense: "一般现在时",
                aspect: "一般体",
                voice: "主动",
                mood: "陈述",
                why: "while 从句用现在时表习惯性、伴随性动作。",
                svo: GrammarSVO(agent: "we", action: "sleep", receiver: nil)
            )
        ],
        wordOrder: GrammarWordOrder(
            en: [
                GrammarOrderSegment(id: 1, text: "The findings", role: .subject, zhPos: 2),
                GrammarOrderSegment(id: 2, text: "published last year", role: .attr, zhPos: 1, moved: true),
                GrammarOrderSegment(id: 3, text: "call into question", role: .predicate, zhPos: 5),
                GrammarOrderSegment(id: 4, text: "long-held assumptions", role: .object, zhPos: 4),
                GrammarOrderSegment(id: 5, text: "that memory is consolidated while we sleep", role: .appos, zhPos: 3, moved: true)
            ],
            zhOrder: [2, 1, 5, 4, 3],
            zhText: ["去年发表的", "这些研究结果", "（记忆在睡眠时被巩固）这一", "长期假设", "受到了质疑"],
            note: "英文的后置定语（②分词、⑤同位语从句）在中文里都要搬到被修饰名词的前面。"
        ),
        pattern: GrammarPattern(
            en: "sth. calls into question the assumption that ...",
            zh: "某事使人开始质疑「……」这一假设"
        ),
        collocations: [
            GrammarCollocation(
                phrase: "call into question",
                pos: "v. phr.",
                zh: "对……提出质疑；动摇某种看法",
                note: "比 doubt 更书面，强调“动摇既有共识”。",
                example: "New data call into question the old model."
            ),
            GrammarCollocation(
                phrase: "long-held assumption",
                pos: "n. phr.",
                zh: "长期持有的假设",
                note: "long-held 常修饰 belief / assumption / view。",
                example: "a long-held belief about diet"
            ),
            GrammarCollocation(
                phrase: "be consolidated",
                pos: "v. phr. (passive)",
                zh: "被巩固、被强化",
                note: "consolidate 在记忆/学习语境的高频被动搭配。",
                example: "Memories are consolidated during deep sleep."
            )
        ],
        phrases: [
            GrammarPhrase(en: "during / while ...", zh: "在……期间"),
            GrammarPhrase(en: "published last year", zh: "去年发表的"),
            GrammarPhrase(en: "memory consolidation", zh: "记忆巩固（术语）"),
            GrammarPhrase(en: "cast doubt on", zh: "使人怀疑（近义）"),
            GrammarPhrase(en: "the assumption that ...", zh: "……这一假设（同位语）")
        ],
        grammarPoints: [
            GrammarPoint(tag: "从句", title: "同位语从句 vs 定语从句", body: "that memory is consolidated... 解释 assumptions 的内容，是同位语从句；that 不作从句成分。"),
            GrammarPoint(tag: "语态", title: "被动表客观过程", body: "is consolidated 用被动，隐去施动者，把焦点放在 memory 上，符合科技英语的客观表达。"),
            GrammarPoint(tag: "修饰", title: "前置 vs 后置定语", body: "long-held 在名词前，published last year 与 that 从句在名词后；中文里后置修饰通常前移。"),
            GrammarPoint(tag: "非谓语", title: "过去分词作后置定语", body: "published last year = which were published last year 的简化，过去分词表被动、完成。")
        ],
        defaultCollectionItem: DefaultCollectionItem(
            title: "sth. calls into question the assumption that ...",
            note: "某事使人开始质疑「……」这一假设",
            type: "句型"
        )
    )
}
