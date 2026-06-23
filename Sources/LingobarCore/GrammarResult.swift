import Foundation

public enum GrammarRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case subject
    case predicate
    case object
    case attr
    case appos
    case adv
    case conj

    public var id: String { rawValue }

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
            defaultCollectionItem: defaultCollectionItem
        )
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
        self.id = try container.decode(String.self, forKey: .id)
        self.role = try container.decode(GrammarRole.self, forKey: .role)
        self.text = try container.decode(String.self, forKey: .text)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? role.zh
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.tokens = try container.decodeIfPresent([GrammarToken].self, forKey: .tokens) ?? []
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
        self.label = try container.decode(String.self, forKey: .label)
        self.role = try container.decode(GrammarRole.self, forKey: .role)
        self.text = try container.decode(String.self, forKey: .text)
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
}

public struct GrammarTrunkItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(role.rawValue)-\(w)" }
    public var w: String
    public var role: GrammarRole

    public init(w: String, role: GrammarRole) {
        self.w = w
        self.role = role
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
        self.id = try container.decode(Int.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.role = try container.decode(GrammarRole.self, forKey: .role)
        self.zhPos = try container.decodeIfPresent(Int.self, forKey: .zhPos) ?? id
        self.moved = try container.decodeIfPresent(Bool.self, forKey: .moved) ?? false
    }
}

public struct GrammarPattern: Codable, Equatable, Sendable {
    public var en: String
    public var zh: String

    public init(en: String, zh: String) {
        self.en = en
        self.zh = zh
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
}

public struct GrammarPhrase: Codable, Equatable, Identifiable, Sendable {
    public var id: String { en }
    public var en: String
    public var zh: String

    public init(en: String, zh: String) {
        self.en = en
        self.zh = zh
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
