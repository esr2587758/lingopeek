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
                    LingobarRow("下一步", "可继续翻译、拆解或收藏为短句。")
                ],
                sideTitle: "可继续处理",
                chips: ["翻译", "拆解", "生成例句"]
            )
        case .translate:
            return LingobarResult(
                title: "自然翻译",
                shortcut: action.shortcut,
                summary: "任何句子都可以变成一个小型学习对象：它能被翻译、拆解、记住，也能继续延展成新的表达。",
                rows: [
                    LingobarRow("原文", source),
                    LingobarRow("语感", "自然、偏产品表达，不像逐词翻译。"),
                    LingobarRow("重点", "learning object 表示可拆解、可存储、可复用的学习对象。")
                ],
                sideTitle: "表达积累",
                chips: ["learning object", "turn into", "in flow", "stay close to"]
            )
        case .parse:
            return LingobarResult(
                title: "语法 / 短语拆解",
                shortcut: action.shortcut,
                summary: "主干是 any sentence can become a small object。后面的 for translation, parsing, memory, and expression 说明用途。",
                rows: [
                    LingobarRow("主语", "any sentence"),
                    LingobarRow("谓语", "can become"),
                    LingobarRow("补足", "a small object for ..."),
                    LingobarRow("并列名词", "translation, parsing, memory, expression")
                ],
                sideTitle: "可替换说法",
                chips: ["a unit of learning", "a reusable phrase", "a piece of language"]
            )
        case .save:
            return LingobarResult(
                title: "收藏到短句库",
                shortcut: action.shortcut,
                summary: "已保存：learning object。这个表达适合描述可被拆解、标注、复用的一段语言材料。",
                rows: [
                    LingobarRow("标签", "product framing, language learning"),
                    LingobarRow("复习", "明天提醒一次，三天后再次出现。")
                ],
                sideTitle: "本地短句库",
                chips: ["learning object", "selection-first", "language layer"]
            )
        case .expand:
            return LingobarResult(
                title: "扩展表达",
                shortcut: action.shortcut,
                summary: "Every piece of text becomes a starting point for understanding, remembering, and expressing yourself better.",
                rows: [
                    LingobarRow("更口语", "Any text, one tap, next step."),
                    LingobarRow("更产品", "A language layer that lives wherever text appears."),
                    LingobarRow("更正式", "It transforms selected text into structured language insight.")
                ],
                sideTitle: "命名语感",
                chips: ["Lingobar", "PhraseBar", "LingoLift"]
            )
        case .examples:
            return LingobarResult(
                title: "例句",
                shortcut: action.shortcut,
                summary: "The app turns every highlighted sentence into a learning object you can translate, break down, and save.",
                rows: [
                    LingobarRow("阅读", "This paragraph becomes a learning object instead of a dead end."),
                    LingobarRow("写作", "Treat each rough sentence as a small object you can refine."),
                    LingobarRow("产品", "The bar makes language feel editable at the point of need.")
                ],
                sideTitle: "搭配",
                chips: ["turn into", "break down", "point of need"]
            )
        case .pronounce:
            return LingobarResult(
                title: "发音",
                shortcut: action.shortcut,
                summary: "learning object /ˈlɝːnɪŋ ˈɑːbdʒekt/。重音落在 learning 和 object 的第一音节。",
                rows: [
                    LingobarRow("节奏", "LEARN-ing OB-ject"),
                    LingobarRow("连读", "learning object 中间自然衔接，不要明显停顿。")
                ],
                sideTitle: "可跟读",
                chips: ["0.75x", "1x", "shadowing"]
            )
        case .ask:
            return LingobarResult(
                title: "表达生成",
                shortcut: action.shortcut,
                summary: "I want to build a selection-first language bar that helps people understand, rewrite, and remember English wherever they are reading or writing.",
                rows: [
                    LingobarRow("语气", "清楚、产品化，比万能工具栏更聚焦。"),
                    LingobarRow("改写", "I want a lightweight language layer that appears whenever text needs understanding."),
                    LingobarRow("用途", "适合作为 pitch、README 或产品首页第一句。")
                ],
                sideTitle: "后续动作",
                chips: ["翻译成英文", "更口语", "更像 pitch", "保存为产品描述"]
            )
        }
    }
}
