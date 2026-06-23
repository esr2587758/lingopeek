import Foundation

public extension GrammarResult {
    static let policyIncentivesFixtureID = "policy-incentives"
    static let engineeringRedesignFixtureID = "engineering-redesign"

    static let grammarUITestFixtures: [GrammarResult] = [
        policyIncentivesFixture,
        engineeringRedesignFixture
    ]

    static func fixture(id: String) -> GrammarResult? {
        switch id {
        case policyIncentivesFixtureID:
            policyIncentivesFixture
        case engineeringRedesignFixtureID:
            engineeringRedesignFixture
        case "mockup", "":
            mockupFixture
        default:
            nil
        }
    }

    static let policyIncentivesFixture = GrammarResult(
        title: "语法解析",
        sourceSentence: "Although the proposal that the council approved in principle was designed to reduce emissions, critics argue that its incentives will benefit companies that have already invested in cleaner technology.",
        chineseMeaning: "虽然市政委员会原则上批准的这项方案旨在减少排放，但批评者认为，它的激励措施会让已经投资清洁技术的公司受益。",
        analysisScopeNote: "长难句 1：让步状语从句 + 定语从句 + 被动不定式目的 + 宾语从句 + 定语从句。",
        chunks: [
            GrammarChunk(
                id: "c",
                role: .conj,
                text: "Although",
                label: "让步连接词",
                note: "Although 引导让步状语从句，中文常译为“虽然”。",
                tokens: [
                    GrammarToken(w: "Although", pos: "从属连词", infl: "引导让步关系，不作句内成分")
                ]
            ),
            GrammarChunk(
                id: "sub-s",
                role: .subject,
                text: "the proposal",
                label: "让步从句主语",
                note: "Although 从句里的主语，核心名词是 proposal。",
                tokens: [
                    GrammarToken(w: "the", pos: "限定词", infl: "定冠词，特指"),
                    GrammarToken(w: "proposal", pos: "名词", infl: "单数，从句主语")
                ]
            ),
            GrammarChunk(
                id: "sub-attr",
                role: .attr,
                text: "that the council approved in principle",
                label: "后置定语从句",
                note: "修饰 proposal；that 在从句中作 approved 的宾语。",
                tokens: [
                    GrammarToken(w: "that", pos: "关系代词", infl: "指代 proposal，作 approved 的宾语"),
                    GrammarToken(w: "the council", pos: "名词短语", infl: "定语从句主语"),
                    GrammarToken(w: "approved", pos: "动词", infl: "一般过去时"),
                    GrammarToken(w: "in principle", pos: "介词短语", infl: "方式/程度状语")
                ]
            ),
            GrammarChunk(
                id: "sub-v",
                role: .predicate,
                text: "was designed to reduce emissions",
                label: "让步从句谓语",
                note: "被动谓语 was designed 后接不定式目的状语。",
                tokens: [
                    GrammarToken(w: "was designed", pos: "被动谓语", infl: "一般过去时被动，was + 过去分词"),
                    GrammarToken(w: "to reduce emissions", pos: "不定式短语", infl: "表目的")
                ]
            ),
            GrammarChunk(
                id: "s",
                role: .subject,
                text: "critics",
                label: "主句主语",
                note: "主句的施事者，表示提出观点的人群。",
                tokens: [
                    GrammarToken(w: "critics", pos: "名词", infl: "复数，谓语 argue 用原形")
                ]
            ),
            GrammarChunk(
                id: "v",
                role: .predicate,
                text: "argue",
                label: "主句谓语",
                note: "一般现在时，表示批评者当前持有的论点。",
                tokens: [
                    GrammarToken(w: "argue", pos: "动词", infl: "一般现在时，主语复数不加 -s")
                ]
            ),
            GrammarChunk(
                id: "o",
                role: .object,
                text: "that its incentives will benefit companies",
                label: "宾语从句",
                note: "that 引导 argue 的内容，说明激励措施会让公司受益。",
                tokens: [
                    GrammarToken(w: "that", pos: "从属连词", infl: "引导宾语从句，可弱读"),
                    GrammarToken(w: "its incentives", pos: "名词短语", infl: "宾语从句主语，复数"),
                    GrammarToken(w: "will benefit", pos: "动词短语", infl: "will + 动词原形，表预测"),
                    GrammarToken(w: "companies", pos: "名词", infl: "复数宾语")
                ]
            ),
            GrammarChunk(
                id: "o-attr",
                role: .attr,
                text: "that have already invested in cleaner technology",
                label: "后置定语从句",
                note: "修饰 companies；完成时强调这些公司已有清洁技术投入。",
                tokens: [
                    GrammarToken(w: "that", pos: "关系代词", infl: "指代 companies，作从句主语"),
                    GrammarToken(w: "have invested", pos: "动词短语", infl: "现在完成时"),
                    GrammarToken(w: "already", pos: "副词", infl: "强调动作已经发生"),
                    GrammarToken(w: "in cleaner technology", pos: "介词短语", infl: "投资方向")
                ]
            )
        ],
        dependencies: [
            GrammarDependency(from: "v", to: "s", label: "主谓"),
            GrammarDependency(from: "v", to: "o", label: "动宾"),
            GrammarDependency(from: "sub-v", to: "sub-s", label: "从句主谓"),
            GrammarDependency(from: "sub-s", to: "sub-attr", label: "后置修饰"),
            GrammarDependency(from: "o", to: "o-attr", label: "后置修饰"),
            GrammarDependency(from: "sub-v", to: "c", label: "让步连接")
        ],
        tree: GrammarTreeNode(
            label: "主句",
            role: .predicate,
            text: "critics argue that ...",
            children: [
                GrammarTreeNode(
                    label: "让步状语从句",
                    role: .adv,
                    text: "Although the proposal ... was designed ...",
                    children: [
                        GrammarTreeNode(label: "连接词", role: .conj, text: "Although"),
                        GrammarTreeNode(
                            label: "从句主语",
                            role: .subject,
                            text: "the proposal",
                            children: [
                                GrammarTreeNode(label: "定语从句", role: .attr, text: "that the council approved in principle")
                            ]
                        ),
                        GrammarTreeNode(label: "从句谓语（被动）", role: .predicate, text: "was designed"),
                        GrammarTreeNode(label: "目的状语", role: .adv, text: "to reduce emissions")
                    ]
                ),
                GrammarTreeNode(label: "主语", role: .subject, text: "critics"),
                GrammarTreeNode(label: "谓语", role: .predicate, text: "argue"),
                GrammarTreeNode(
                    label: "宾语从句",
                    role: .object,
                    text: "that its incentives will benefit companies ...",
                    children: [
                        GrammarTreeNode(label: "从句主语", role: .subject, text: "its incentives"),
                        GrammarTreeNode(label: "从句谓语", role: .predicate, text: "will benefit"),
                        GrammarTreeNode(
                            label: "从句宾语",
                            role: .object,
                            text: "companies",
                            children: [
                                GrammarTreeNode(label: "定语从句", role: .attr, text: "that have already invested in cleaner technology")
                            ]
                        )
                    ]
                )
            ]
        ),
        trunk: GrammarTrunk(
            core: [
                GrammarTrunkItem(w: "critics", role: .subject),
                GrammarTrunkItem(w: "argue", role: .predicate),
                GrammarTrunkItem(w: "that its incentives will benefit companies", role: .object)
            ],
            dropped: [
                "Although ... was designed to reduce emissions（让步状语从句）",
                "that the council approved in principle（修饰 proposal）",
                "that have already invested in cleaner technology（修饰 companies）"
            ],
            coreZh: "批评者认为，这些激励会让公司受益。"
        ),
        tenseVoice: [
            GrammarTenseClause(
                scope: "让步状语从句",
                verb: "was designed",
                tense: "一般过去时",
                aspect: "一般体",
                voice: "被动",
                mood: "陈述",
                why: "方案是被设计出来的，施动者不重要；过去时对应已经批准的政策设计。",
                svo: GrammarSVO(agent: "(policy makers，被省略)", action: "design", receiver: "the proposal")
            ),
            GrammarTenseClause(
                scope: "主句",
                verb: "argue",
                tense: "一般现在时",
                aspect: "一般体",
                voice: "主动",
                mood: "陈述",
                why: "一般现在时表达当前公开立场或持续有效的论点。",
                svo: GrammarSVO(agent: "critics", action: "argue", receiver: "that-clause")
            ),
            GrammarTenseClause(
                scope: "宾语从句",
                verb: "will benefit",
                tense: "一般将来时",
                aspect: "一般体",
                voice: "主动",
                mood: "陈述",
                why: "will 表示批评者对政策效果的预测。",
                svo: GrammarSVO(agent: "its incentives", action: "benefit", receiver: "companies")
            ),
            GrammarTenseClause(
                scope: "companies 定语从句",
                verb: "have already invested",
                tense: "现在完成时",
                aspect: "完成体",
                voice: "主动",
                mood: "陈述",
                why: "完成时强调过去投资对现在受益资格造成的影响。",
                svo: GrammarSVO(agent: "companies", action: "invest", receiver: "in cleaner technology")
            )
        ],
        wordOrder: GrammarWordOrder(
            en: [
                GrammarOrderSegment(id: 1, text: "Although", role: .conj, zhPos: 1),
                GrammarOrderSegment(id: 2, text: "the proposal", role: .subject, zhPos: 3),
                GrammarOrderSegment(id: 3, text: "that the council approved in principle", role: .attr, zhPos: 2, moved: true),
                GrammarOrderSegment(id: 4, text: "was designed to reduce emissions", role: .predicate, zhPos: 4),
                GrammarOrderSegment(id: 5, text: "critics", role: .subject, zhPos: 5),
                GrammarOrderSegment(id: 6, text: "argue", role: .predicate, zhPos: 6),
                GrammarOrderSegment(id: 7, text: "that its incentives will benefit companies", role: .object, zhPos: 8),
                GrammarOrderSegment(id: 8, text: "that have already invested in cleaner technology", role: .attr, zhPos: 7, moved: true)
            ],
            zhOrder: [1, 3, 2, 4, 5, 6, 8, 7],
            zhText: ["虽然", "市政委员会原则上批准的", "这项方案", "旨在减少排放", "批评者", "认为", "已经投资清洁技术的", "公司会受益"],
            note: "英文定语从句跟在名词后面，中文通常把 ③ 和 ⑧ 提前到被修饰名词前。"
        ),
        pattern: GrammarPattern(
            en: "Although ..., critics argue that ...",
            zh: "虽然……，但批评者认为……"
        ),
        collocations: [
            GrammarCollocation(
                phrase: "approve in principle",
                pos: "v. phr.",
                zh: "原则上批准",
                note: "常用于政策、协议、预算尚未最终落地的阶段。",
                example: "The board approved the plan in principle."
            ),
            GrammarCollocation(
                phrase: "be designed to do sth.",
                pos: "v. phr.",
                zh: "旨在做某事",
                note: "被动结构强调用途或设计目的。",
                example: "The tool is designed to reduce errors."
            ),
            GrammarCollocation(
                phrase: "invest in technology",
                pos: "v. phr.",
                zh: "投资技术",
                note: "in 后接投入方向或资产类别。",
                example: "Many firms invest in cleaner technology."
            )
        ],
        phrases: [
            GrammarPhrase(en: "in principle", zh: "原则上"),
            GrammarPhrase(en: "reduce emissions", zh: "减少排放"),
            GrammarPhrase(en: "its incentives", zh: "它的激励措施"),
            GrammarPhrase(en: "cleaner technology", zh: "更清洁的技术"),
            GrammarPhrase(en: "critics argue that ...", zh: "批评者认为……")
        ],
        grammarPoints: [
            GrammarPoint(tag: "从句", title: "Although 引导让步状语从句", body: "Although 从句放在句首，先承认方案目的，再转入 critics 的反对观点。"),
            GrammarPoint(tag: "修饰", title: "that 定语从句后置", body: "that the council approved... 修饰 proposal；中文要前移为“市政委员会批准的方案”。"),
            GrammarPoint(tag: "语态", title: "was designed 的被动焦点", body: "被动语态把焦点放在 proposal 的用途，而不是谁设计了方案。"),
            GrammarPoint(tag: "时态", title: "现在完成时强调已有投入", body: "have already invested 表示过去完成的投资影响现在的政策受益。")
        ],
        defaultCollectionItem: DefaultCollectionItem(
            title: "Although ..., critics argue that ...",
            note: "虽然……，但批评者认为……",
            type: "句型"
        )
    )

    static let engineeringRedesignFixture = GrammarResult(
        title: "语法解析",
        sourceSentence: "By the time the report was released, the engineers who had warned that the system might fail under heavy load had already redesigned the module that controlled authentication.",
        chineseMeaning: "到报告发布时，那些曾警告系统可能在高负载下失效的工程师，已经重新设计了控制身份验证的模块。",
        analysisScopeNote: "长难句 2：时间状语从句 + 被动 + 定语从句 + 宾语从句 + 情态动词 + 过去完成时。",
        chunks: [
            GrammarChunk(
                id: "adv",
                role: .adv,
                text: "By the time the report was released",
                label: "时间状语从句",
                note: "说明主句动作完成时的时间边界。",
                tokens: [
                    GrammarToken(w: "By the time", pos: "连接短语", infl: "引导时间状语，强调截止点"),
                    GrammarToken(w: "the report", pos: "名词短语", infl: "从句主语"),
                    GrammarToken(w: "was released", pos: "被动谓语", infl: "一般过去时被动")
                ]
            ),
            GrammarChunk(
                id: "s",
                role: .subject,
                text: "the engineers",
                label: "主语",
                note: "主句主语，核心名词是 engineers。",
                tokens: [
                    GrammarToken(w: "the", pos: "限定词", infl: "定冠词，特指"),
                    GrammarToken(w: "engineers", pos: "名词", infl: "复数，主句主语")
                ]
            ),
            GrammarChunk(
                id: "s-attr",
                role: .attr,
                text: "who had warned that the system might fail under heavy load",
                label: "后置定语从句",
                note: "修饰 engineers，并说明这些工程师之前提出过系统风险。",
                tokens: [
                    GrammarToken(w: "who", pos: "关系代词", infl: "指代 engineers，作从句主语"),
                    GrammarToken(w: "had warned", pos: "动词短语", infl: "过去完成时"),
                    GrammarToken(w: "that the system might fail", pos: "宾语从句", infl: "warned 的内容"),
                    GrammarToken(w: "under heavy load", pos: "介词短语", infl: "条件状语")
                ]
            ),
            GrammarChunk(
                id: "v",
                role: .predicate,
                text: "had already redesigned",
                label: "主句谓语",
                note: "过去完成时，表示在 report released 这个过去时间点之前已经完成。",
                tokens: [
                    GrammarToken(w: "had", pos: "助动词", infl: "过去完成时标记"),
                    GrammarToken(w: "already", pos: "副词", infl: "强调完成早于参照时间"),
                    GrammarToken(w: "redesigned", pos: "过去分词", infl: "完成体主动结构中的主要动词")
                ]
            ),
            GrammarChunk(
                id: "o",
                role: .object,
                text: "the module",
                label: "宾语",
                note: "主句宾语，后面的 that 从句说明模块的功能。",
                tokens: [
                    GrammarToken(w: "the", pos: "限定词", infl: "定冠词，特指"),
                    GrammarToken(w: "module", pos: "名词", infl: "单数宾语")
                ]
            ),
            GrammarChunk(
                id: "o-attr",
                role: .attr,
                text: "that controlled authentication",
                label: "后置定语从句",
                note: "修饰 module；that 在从句中作主语。",
                tokens: [
                    GrammarToken(w: "that", pos: "关系代词", infl: "指代 module，作从句主语"),
                    GrammarToken(w: "controlled", pos: "动词", infl: "一般过去时"),
                    GrammarToken(w: "authentication", pos: "名词", infl: "controlled 的宾语")
                ]
            )
        ],
        dependencies: [
            GrammarDependency(from: "v", to: "s", label: "主谓"),
            GrammarDependency(from: "v", to: "o", label: "动宾"),
            GrammarDependency(from: "v", to: "adv", label: "时间状语"),
            GrammarDependency(from: "s", to: "s-attr", label: "后置修饰"),
            GrammarDependency(from: "o", to: "o-attr", label: "后置修饰")
        ],
        tree: GrammarTreeNode(
            label: "主句",
            role: .predicate,
            text: "the engineers ... had already redesigned the module ...",
            children: [
                GrammarTreeNode(
                    label: "时间状语从句",
                    role: .adv,
                    text: "By the time the report was released",
                    children: [
                        GrammarTreeNode(label: "从句主语", role: .subject, text: "the report"),
                        GrammarTreeNode(label: "从句谓语（被动）", role: .predicate, text: "was released")
                    ]
                ),
                GrammarTreeNode(
                    label: "主语",
                    role: .subject,
                    text: "the engineers",
                    children: [
                        GrammarTreeNode(
                            label: "定语从句",
                            role: .attr,
                            text: "who had warned that ...",
                            children: [
                                GrammarTreeNode(label: "从句谓语", role: .predicate, text: "had warned"),
                                GrammarTreeNode(
                                    label: "宾语从句",
                                    role: .object,
                                    text: "that the system might fail under heavy load",
                                    children: [
                                        GrammarTreeNode(label: "从句主语", role: .subject, text: "the system"),
                                        GrammarTreeNode(label: "情态谓语", role: .predicate, text: "might fail"),
                                        GrammarTreeNode(label: "条件状语", role: .adv, text: "under heavy load")
                                    ]
                                )
                            ]
                        )
                    ]
                ),
                GrammarTreeNode(label: "谓语", role: .predicate, text: "had already redesigned"),
                GrammarTreeNode(
                    label: "宾语",
                    role: .object,
                    text: "the module",
                    children: [
                        GrammarTreeNode(label: "定语从句", role: .attr, text: "that controlled authentication")
                    ]
                )
            ]
        ),
        trunk: GrammarTrunk(
            core: [
                GrammarTrunkItem(w: "the engineers", role: .subject),
                GrammarTrunkItem(w: "had redesigned", role: .predicate),
                GrammarTrunkItem(w: "the module", role: .object)
            ],
            dropped: [
                "By the time the report was released（时间状语从句）",
                "who had warned that the system might fail under heavy load（修饰 engineers）",
                "that controlled authentication（修饰 module）"
            ],
            coreZh: "工程师已经重新设计了模块。"
        ),
        tenseVoice: [
            GrammarTenseClause(
                scope: "时间状语从句",
                verb: "was released",
                tense: "一般过去时",
                aspect: "一般体",
                voice: "被动",
                mood: "陈述",
                why: "报告是被发布的，句子关注发布时间而非发布者。",
                svo: GrammarSVO(agent: "(authors/team，被省略)", action: "release", receiver: "the report")
            ),
            GrammarTenseClause(
                scope: "engineers 定语从句",
                verb: "had warned",
                tense: "过去完成时",
                aspect: "完成体",
                voice: "主动",
                mood: "陈述",
                why: "had warned 说明警告发生在主句重新设计之前或更早的过去背景中。",
                svo: GrammarSVO(agent: "the engineers", action: "warn", receiver: "that-clause")
            ),
            GrammarTenseClause(
                scope: "warned 的宾语从句",
                verb: "might fail",
                tense: "情态过去式",
                aspect: "一般体",
                voice: "主动",
                mood: "虚拟",
                why: "might 表示风险和不确定性，不断言系统一定会失败。",
                svo: GrammarSVO(agent: "the system", action: "fail", receiver: nil)
            ),
            GrammarTenseClause(
                scope: "主句",
                verb: "had already redesigned",
                tense: "过去完成时",
                aspect: "完成体",
                voice: "主动",
                mood: "陈述",
                why: "过去完成时把 redesigned 放在 report was released 之前，形成清楚的先后顺序。",
                svo: GrammarSVO(agent: "the engineers", action: "redesign", receiver: "the module")
            ),
            GrammarTenseClause(
                scope: "module 定语从句",
                verb: "controlled",
                tense: "一般过去时",
                aspect: "一般体",
                voice: "主动",
                mood: "陈述",
                why: "controlled 描述该模块当时承担的功能。",
                svo: GrammarSVO(agent: "the module", action: "control", receiver: "authentication")
            )
        ],
        wordOrder: GrammarWordOrder(
            en: [
                GrammarOrderSegment(id: 1, text: "By the time the report was released", role: .adv, zhPos: 1),
                GrammarOrderSegment(id: 2, text: "the engineers", role: .subject, zhPos: 4),
                GrammarOrderSegment(id: 3, text: "who had warned that the system might fail under heavy load", role: .attr, zhPos: 2, moved: true),
                GrammarOrderSegment(id: 4, text: "had already redesigned", role: .predicate, zhPos: 5),
                GrammarOrderSegment(id: 5, text: "the module", role: .object, zhPos: 7),
                GrammarOrderSegment(id: 6, text: "that controlled authentication", role: .attr, zhPos: 6, moved: true)
            ],
            zhOrder: [1, 3, 2, 4, 6, 5],
            zhText: ["到报告发布时", "曾警告系统可能在高负载下失效的", "工程师", "已经重新设计了", "控制身份验证的", "模块"],
            note: "英文把 who/that 定语从句放在名词后，中文要把 ③ 和 ⑥ 移到名词前。"
        ),
        pattern: GrammarPattern(
            en: "By the time ..., S had already ...",
            zh: "到……的时候，主语已经……"
        ),
        collocations: [
            GrammarCollocation(
                phrase: "by the time",
                pos: "conj. phr.",
                zh: "到……的时候",
                note: "常和完成时搭配，用来建立先后时间关系。",
                example: "By the time we arrived, the meeting had ended."
            ),
            GrammarCollocation(
                phrase: "under heavy load",
                pos: "prep. phr.",
                zh: "在高负载下",
                note: "工程语境中描述系统压力条件。",
                example: "The service slowed under heavy load."
            ),
            GrammarCollocation(
                phrase: "control authentication",
                pos: "v. phr.",
                zh: "控制身份验证",
                note: "control 后接系统模块负责的功能。",
                example: "This module controls authentication."
            )
        ],
        phrases: [
            GrammarPhrase(en: "was released", zh: "被发布"),
            GrammarPhrase(en: "had warned that ...", zh: "曾警告说……"),
            GrammarPhrase(en: "might fail", zh: "可能会失效"),
            GrammarPhrase(en: "redesigned the module", zh: "重新设计模块"),
            GrammarPhrase(en: "authentication", zh: "身份验证")
        ],
        grammarPoints: [
            GrammarPoint(tag: "时态", title: "过去完成时建立先后顺序", body: "had already redesigned 发生在 was released 之前，所以用过去完成时。"),
            GrammarPoint(tag: "从句", title: "who 定语从句修饰主语", body: "who had warned... 把 engineers 限定为“曾经发出警告的那批工程师”。"),
            GrammarPoint(tag: "语气", title: "might 表示风险而非事实", body: "might fail 只表达可能性，语气比 would fail 更谨慎。"),
            GrammarPoint(tag: "修饰", title: "that controlled authentication 后置", body: "英语用后置定语从句修饰 module，中文要前移成“控制身份验证的模块”。")
        ],
        defaultCollectionItem: DefaultCollectionItem(
            title: "By the time ..., S had already ...",
            note: "到……的时候，主语已经……",
            type: "句型"
        )
    )
}
