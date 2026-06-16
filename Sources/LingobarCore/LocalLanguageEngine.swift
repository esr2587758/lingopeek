import Foundation

public struct LocalLanguageEngine: Sendable {
    public init() {}

    public func result(for action: LanguageAction, text: String) -> LingobarResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty
            ? "any sentence can become a small object for translation, parsing, memory, and expression."
            : trimmed

        switch action {
        case .copy:
            return LingobarResult(
                title: "已复制选区",
                shortcut: action.shortcut,
                summary: source,
                rows: [
                    LingobarRow("选区", "保留原文，方便复制到笔记、聊天或文档。"),
                    LingobarRow("下一步", "可继续翻译、语法分析或收藏为短句。")
                ],
                sideTitle: "可继续处理",
                chips: ["翻译", "语法", "生成例句"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: source
            )
        case .translate:
            return LingobarResult(
                title: "翻译",
                shortcut: action.shortcut,
                summary: "这些发现使人们对“睡眠期间记忆如何巩固”这一长期假设产生了质疑。",
                rows: [
                    LingobarRow("原文", source),
                    LingobarRow("通用", "这些发现让人们开始质疑关于睡眠如何帮助巩固记忆的长期假设。"),
                    LingobarRow("书面", "这些发现对有关睡眠促进记忆巩固机制的长期假设提出了质疑。"),
                    LingobarRow("意译", "这项研究让我们重新思考：睡眠到底是否像过去认为的那样帮助大脑保存记忆。"),
                    LingobarRow("语感", "通用版本更自然，书面版本更适合报告或论文，意译版本更强调整体意思。")
                ],
                sideTitle: "翻译选项",
                chips: ["通用翻译", "书面表达", "意译", "语感"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: "这些发现让人们开始质疑关于睡眠如何帮助巩固记忆的长期假设。"
            )
        case .grammar:
            return LingobarResult(
                title: "语法",
                shortcut: action.shortcut,
                summary: "这句话的主干是 The findings call into question assumptions，后面的 about how... 说明被质疑的具体假设。",
                rows: [
                    LingobarRow("主句", "The findings call into question ... assumptions"),
                    LingobarRow("固定搭配", "call into question"),
                    LingobarRow("后置定语", "long-held assumptions about how ..."),
                    LingobarRow("宾语从句", "how memory consolidates during sleep")
                ],
                sideTitle: "拆解粒度",
                chips: ["主干", "完整", "中文", "术语"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: "sth. calls into question assumptions about how …"
            )
        case .collect:
            return LingobarResult(
                title: "收藏",
                shortcut: action.shortcut,
                summary: "已收藏：learning object。这个表达适合描述可被拆解、标注、复用的一段语言材料。",
                rows: [
                    LingobarRow("标签", "product framing, language learning"),
                    LingobarRow("复习", "明天提醒一次，三天后再次出现。")
                ],
                sideTitle: "本地短句库",
                chips: ["learning object", "selection-first", "language layer"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: source
            )
        case .rewrite:
            return LingobarResult(
                title: "改写",
                shortcut: action.shortcut,
                summary: "These results challenge what we've long assumed about how sleep helps the brain lock in memories.",
                rows: [
                    LingobarRow("更口语", "Turns out what we thought about memory and sleep might be wrong."),
                    LingobarRow("更正式", "The evidence undermines prevailing assumptions regarding sleep-dependent memory consolidation."),
                    LingobarRow("更简洁", "This study makes us rethink how sleep stores our memories.")
                ],
                sideTitle: "改写方向",
                chips: ["更口语", "更正式", "更简洁", "更地道"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: "These results challenge what we've long assumed about how sleep helps the brain lock in memories."
            )
        case .examples:
            return LingobarResult(
                title: "例句",
                shortcut: action.shortcut,
                summary: "The report calls into question the safety of the new drug.",
                rows: [
                    LingobarRow("2", "Her testimony calls into question everything we believed about that night."),
                    LingobarRow("3", "These numbers call into question the company's growth story.")
                ],
                sideTitle: "同结构句型 · 可直接套用",
                chips: ["搭配", "同结构", "同场景", "基础"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: "The report calls into question the safety of the new drug."
            )
        case .pronounce:
            return LingobarResult(
                title: "发音",
                shortcut: action.shortcut,
                summary: "consolidate /kənˈsɑː.lə.deɪt/。重音在第二音节 -sol-。",
                rows: [
                    LingobarRow("节奏", "con-SOL-i-date"),
                    LingobarRow("连读", "memory consolidates during sleep 中自然连接，不要逐词停顿。")
                ],
                sideTitle: "可跟读",
                chips: ["美音", "英音", "正常", "慢速"],
                moreActionTitle: action.moreActionTitle,
                defaultCollectionTitle: "consolidate"
            )
        }
    }
}
