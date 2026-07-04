import CoreGraphics
import Foundation
import ImageIO
import LingobarCore
import LingobarUI
import SwiftUI
import UniformTypeIdentifiers

enum GrammarUICheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw GrammarUICheckFailure.failed(message)
    }
}

@main
struct LingoPeekGrammarUIChecks {
    @MainActor
    static func main() async {
        do {
            let shouldBenchmark = CommandLine.arguments.contains("--benchmark")
            if let screenshotURL = requestedOverlapScreenshotURL() {
                try exportOverlappingClauseRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar overlap regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedAdverbialScreenshotURL() {
                try exportAdverbialGranularityRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar adverbial regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedNativeDependencyScreenshotURL() {
                try exportNativeDependencyRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar native dependency regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedDependencyHoverScreenshotURL() {
                try exportDependencyHoverRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar dependency hover regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedDependencyHoverMatrixScreenshotURL() {
                try exportDependencyHoverMatrixScreenshot(to: screenshotURL)
                print("Wrote grammar dependency hover matrix screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedRelativePronounScreenshotURL() {
                try exportRelativePronounRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar relative pronoun regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedColonRecoveryScreenshotURL() {
                try exportColonRecoveryRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar colon recovery regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedCopularComplementScreenshotURL() {
                try exportCopularComplementRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar copular complement regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedInvertedCopularScreenshotURL() {
                try exportInvertedCopularRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar inverted copular regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedLongSchemaRecoveryScreenshotURL() {
                try exportLongSchemaRecoveryRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar long-schema recovery regression screenshot to \(screenshotURL.path)")
                return
            }
            if let screenshotURL = requestedPassiveContrastRecoveryScreenshotURL() {
                try exportPassiveContrastRecoveryRegressionScreenshot(to: screenshotURL)
                print("Wrote grammar passive-contrast recovery regression screenshot to \(screenshotURL.path)")
                return
            }

            try check(
                GrammarVizView.allCases.map(\.rawValue) == ["annotated", "dependency", "tree", "trunk", "tense", "order"],
                "Grammar panel should expose exactly the six expected tabs"
            )
            try check(
                GrammarResult.grammarUITestFixtures.count == 2,
                "Grammar UI checks should render exactly two long-sentence fixtures"
            )

            for fixture in GrammarResult.grammarUITestFixtures {
                try assertAllGrammarTabsRender(for: fixture)
            }
            try assertSparseAIGrammarResponseRenders()
            try assertOverlappingClauseRegressionRenders()
            try assertAdverbialGranularityRegressionRenders()
            try assertNativeDependencyRegressionRenders()
            try assertDependencyHoverRegressionRenders()
            try assertRelativePronounRegressionRenders()
            try assertColonRecoveryRegressionRenders()
            try assertCopularComplementRegressionRenders()
            try assertInvertedCopularRegressionRenders()
            try assertLongSchemaRecoveryRegressionRenders()
            try assertPassiveContrastRecoveryRegressionRenders()

            if shouldBenchmark {
                try await runBenchmarks()
            }

            print("LingoPeekGrammarUIChecks passed")
        } catch {
            fputs("LingoPeekGrammarUIChecks failed: \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func assertAllGrammarTabsRender(for fixture: GrammarResult) throws {
        for tab in GrammarVizView.allCases {
            let content = GrammarResultPanel(result: fixture, initialView: tab)
                .frame(width: 720)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 1
            renderer.proposedSize = ProposedViewSize(width: 720, height: nil)

            guard let image = renderer.cgImage else {
                throw GrammarUICheckFailure.failed("\(fixture.sourceSentence) \(tab.rawValue) should render a CGImage")
            }

            try check(image.width >= 700, "\(tab.rawValue) tab should render at panel width")
            try check(image.height > 260, "\(tab.rawValue) tab should render real content")
            try check(visiblePixelCount(in: image) > 800, "\(tab.rawValue) tab should not be blank")
        }
    }

    @MainActor
    private static func assertSparseAIGrammarResponseRenders() throws {
        let json = """
        {
          "title": "语法解析",
          "sourceSentence": "Although the plan looked simple, the constraints made implementation harder.",
          "chineseMeaning": "虽然计划看起来简单，但这些限制让实现更困难。",
          "chunks": [
            { "id": 1, "role": "连接词", "text": "Although", "tokens": ["Although"] },
            { "id": 2, "role": "subject", "text": "the plan", "tokens": [{ "w": "plan" }] },
            { "id": 3, "role": "predicate", "text": "looked simple", "note": "让步从句谓语" },
            { "id": 4, "role": "subject", "text": "the constraints" },
            { "id": 5, "role": "predicate", "text": "made", "tokens": [{ "w": "made", "pos": "动词" }] },
            { "id": 6, "role": "object", "text": "implementation harder" }
          ],
          "dependencies": [
            { "from": 3, "to": 2 },
            [5, 4, "主谓"],
            { "from": 5, "to": 4, "label": "主谓" },
            { "from": 5, "to": 6, "label": "动宾" }
          ],
          "tree": {
            "label": "复句",
            "text": "Although ... harder",
            "children": [
              { "label": "让步从句", "role": "adv", "text": "Although the plan looked simple" },
              { "label": "主句", "role": "predicate", "text": "the constraints made implementation harder" }
            ]
          },
          "trunk": {
            "core": [
              { "w": "the constraints", "role": "subject" },
              { "w": "made", "role": "predicate" },
              { "w": "implementation harder", "role": "object" }
            ],
            "dropped": [
              { "text": "Although the plan looked simple", "role": "adv" }
            ]
          },
          "tenseVoice": [
            { "scope": "主句", "verb": "made", "tense": "一般过去时" }
          ],
          "wordOrder": {
            "en": [
              { "id": "1", "text": "Although the plan looked simple", "role": "adv", "moved": "false" },
              { "id": 2, "text": "the constraints", "role": "subject" },
              { "id": 3, "text": "made", "role": "predicate" },
              { "id": 4, "text": "implementation harder", "role": "object" }
            ],
            "zhOrder": "1,2,4,3",
            "zhText": "虽然计划看起来简单 / 这些限制 / 实现更困难 / 让"
          },
          "pattern": { "en": "Although X, Y made Z harder.", "zh": "虽然 X，但 Y 让 Z 更困难。" },
          "defaultCollectionItem": { "title": "Although X, Y made Z harder." },
          "collocations": ["make implementation harder"],
          "phrases": ["look simple"],
          "grammarPoints": ["although 引导让步"]
        }
        """
        let fixture = try JSONDecoder().decode(GrammarResult.self, from: Data(json.utf8))
        try check(fixture.chunks.first?.role == .conj, "sparse AI fixture should accept Chinese role labels")
        try check(fixture.chunks.first?.id == "1", "sparse AI fixture should accept numeric chunk ids")
        try check(fixture.dependencies.first?.from == "3", "sparse AI fixture should accept numeric dependency ids")
        try check(fixture.dependencies[1].from == "5", "sparse AI fixture should accept tuple dependency edges")
        try check(fixture.trunk.dropped.first == "Although the plan looked simple", "sparse AI fixture should accept object dropped phrases")
        try check(fixture.wordOrder.en.first?.id == 1, "sparse AI fixture should accept string word-order ids")
        try check(fixture.wordOrder.zhOrder == [1, 2, 4, 3], "sparse AI fixture should accept string zhOrder")
        try check(fixture.wordOrder.zhText.count == 1, "sparse AI fixture should accept string zhText")
        try check(fixture.chunks[1].tokens.first?.infl == "", "sparse AI fixture should default missing token inflection")
        try check(fixture.collocations.first?.example == "", "sparse AI fixture should default missing examples")
        try assertAllGrammarTabsRender(for: fixture)
    }

    @MainActor
    private static func assertOverlappingClauseRegressionRenders() throws {
        let fixture = try overlappingClauseRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "overlap regression annotated tab should render at panel width")
        try check(image.height > 260, "overlap regression annotated tab should render real content")
        try check(visiblePixelCount(in: image) > 800, "overlap regression annotated tab should not be blank")
    }

    @MainActor
    private static func exportOverlappingClauseRegressionScreenshot(to url: URL) throws {
        let fixture = try overlappingClauseRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    @MainActor
    private static func overlappingClauseRegressionFixture() throws -> GrammarResult {
        let source = "This means you can keep your main application responsive (e.g., a web server or UI) while the agent continues its work, only inspecting the result when you need it."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "s", role: .subject, text: "This", label: "主语", note: "代词作主语"),
                GrammarChunk(id: "v", role: .predicate, text: "means", label: "谓语", note: "及物动词"),
                GrammarChunk(
                    id: "o",
                    role: .object,
                    text: "you can keep your main application responsive (e.g., a web server or UI) while the agent continues its work, only inspecting the result when you need it",
                    label: "宾语从句",
                    note: "整个从句作宾语"
                ),
                GrammarChunk(id: "sub-s", role: .subject, text: "you", label: "从句主语", note: "宾语从句中的主语"),
                GrammarChunk(id: "sub-v", role: .predicate, text: "can keep", label: "从句谓语", note: "情态动词 + 动词原形"),
                GrammarChunk(
                    id: "sub-o",
                    role: .object,
                    text: "your main application responsive (e.g., a web server or UI)",
                    label: "从句宾语",
                    note: "keep 的宾语和宾补"
                ),
                GrammarChunk(
                    id: "adv",
                    role: .adv,
                    text: "while the agent continues its work, only inspecting the result when you need it",
                    label: "状语",
                    note: "说明并行动作和检查时机"
                )
            ],
            in: source
        )

        try check(!chunks.contains { $0.id == "o" }, "overlap regression should remove the duplicated parent object clause")
        try check(chunks.count == 6, "overlap regression should keep six flat chunks")

        return GrammarResult(
            title: "语法解析",
            sourceSentence: source,
            chineseMeaning: "这意味着你可以保持主应用响应，同时代理继续工作，只在需要时检查结果。",
            analysisScopeNote: "回归用例：宾语从句父级与子成分不应重复渲染。",
            chunks: chunks,
            dependencies: [
                GrammarDependency(from: "v", to: "s", label: "主谓"),
                GrammarDependency(from: "sub-v", to: "sub-s", label: "从句主谓"),
                GrammarDependency(from: "sub-v", to: "sub-o", label: "动宾"),
                GrammarDependency(from: "sub-v", to: "adv", label: "状语")
            ],
            tree: GrammarTreeNode(
                label: "主句",
                role: .predicate,
                text: "This means ...",
                children: [
                    GrammarTreeNode(label: "主语", role: .subject, text: "This"),
                    GrammarTreeNode(label: "谓语", role: .predicate, text: "means"),
                    GrammarTreeNode(
                        label: "宾语从句",
                        role: .object,
                        text: "you can keep ...",
                        children: [
                            GrammarTreeNode(label: "从句主语", role: .subject, text: "you"),
                            GrammarTreeNode(label: "从句谓语", role: .predicate, text: "can keep"),
                            GrammarTreeNode(label: "从句宾语", role: .object, text: "your main application responsive ..."),
                            GrammarTreeNode(label: "时间状语", role: .adv, text: "while the agent continues ...")
                        ]
                    )
                ]
            ),
            trunk: GrammarTrunk(
                core: [
                    GrammarTrunkItem(w: "This", role: .subject),
                    GrammarTrunkItem(w: "means", role: .predicate),
                    GrammarTrunkItem(w: "you can keep your main application responsive", role: .object)
                ],
                dropped: [
                    "while the agent continues its work（时间/伴随状语）",
                    "only inspecting the result when you need it（补充状语）"
                ],
                coreZh: "这意味着你可以保持主应用响应。"
            ),
            tenseVoice: [
                GrammarTenseClause(
                    scope: "主句",
                    verb: "means",
                    tense: "一般现在时",
                    aspect: "一般体",
                    voice: "主动",
                    mood: "陈述",
                    why: "means 用一般现在时说明当前结论。",
                    svo: GrammarSVO(agent: "This", action: "mean", receiver: "that-clause")
                ),
                GrammarTenseClause(
                    scope: "宾语从句",
                    verb: "can keep",
                    tense: "一般现在时",
                    aspect: "一般体",
                    voice: "主动",
                    mood: "情态",
                    why: "can 表示能力或可能性。",
                    svo: GrammarSVO(agent: "you", action: "keep", receiver: "your main application responsive")
                )
            ],
            wordOrder: GrammarWordOrder(
                en: [
                    GrammarOrderSegment(id: 1, text: "This", role: .subject, zhPos: 1),
                    GrammarOrderSegment(id: 2, text: "means", role: .predicate, zhPos: 2),
                    GrammarOrderSegment(id: 3, text: "you", role: .subject, zhPos: 3),
                    GrammarOrderSegment(id: 4, text: "can keep", role: .predicate, zhPos: 4),
                    GrammarOrderSegment(id: 5, text: "your main application responsive", role: .object, zhPos: 5),
                    GrammarOrderSegment(id: 6, text: "while the agent continues its work", role: .adv, zhPos: 6)
                ],
                zhOrder: [1, 2, 3, 4, 5, 6],
                zhText: ["这", "意味着", "你", "可以保持", "主应用响应", "同时代理继续工作"],
                note: "英文和中文主干顺序接近，状语可自然后置。"
            ),
            pattern: GrammarPattern(en: "This means S can V while ...", zh: "这意味着某人可以……，同时……"),
            collocations: [
                GrammarCollocation(phrase: "keep responsive", pos: "v. phr.", zh: "保持响应", note: "常用于应用或服务可用性。", example: "The UI stays responsive."),
                GrammarCollocation(phrase: "inspect the result", pos: "v. phr.", zh: "检查结果", note: "强调只查看产出。", example: "Inspect the result after the task finishes."),
                GrammarCollocation(phrase: "continue its work", pos: "v. phr.", zh: "继续工作", note: "表示后台任务不停顿。", example: "The worker continues its work.")
            ],
            phrases: [
                GrammarPhrase(en: "main application", zh: "主应用"),
                GrammarPhrase(en: "web server or UI", zh: "Web 服务器或界面"),
                GrammarPhrase(en: "when you need it", zh: "在你需要时")
            ],
            grammarPoints: [
                GrammarPoint(tag: "从句", title: "means 后接宾语从句", body: "means 的内容由后面的从句说明。"),
                GrammarPoint(tag: "时态", title: "can 表示能力", body: "can keep 表示可以做到保持响应。"),
                GrammarPoint(tag: "修饰", title: "while 引导伴随状语", body: "while 从句说明主应用响应期间代理仍在工作。")
            ],
            defaultCollectionItem: DefaultCollectionItem(
                title: "This means S can V while ...",
                note: "这意味着某人可以……，同时……",
                type: "句型"
            )
        )

    }

    @MainActor
    private static func assertAdverbialGranularityRegressionRenders() throws {
        let fixture = try adverbialGranularityRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "adverbial regression annotated tab should render at panel width")
        try check(image.height > 260, "adverbial regression annotated tab should render real content")
        try check(visiblePixelCount(in: image) > 800, "adverbial regression annotated tab should not be blank")
    }

    @MainActor
    private static func exportAdverbialGranularityRegressionScreenshot(to url: URL) throws {
        let fixture = try adverbialGranularityRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    @MainActor
    private static func adverbialGranularityRegressionFixture() throws -> GrammarResult {
        let source = "Search and Fetch connects to PatSnap patent and paper search and fetch capabilities, allowing the AI assistant to search for relevant records and retrieve detailed information for selected items."
        let coarseAdverbial = "allowing the AI assistant to search for relevant records and retrieve detailed information for selected items"
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "s", role: .subject, text: "Search and Fetch", label: "主语", note: "专有名词，功能名称"),
                GrammarChunk(id: "v", role: .predicate, text: "connects to", label: "谓语", note: "动词短语，表示连接"),
                GrammarChunk(
                    id: "o",
                    role: .object,
                    text: "PatSnap patent and paper search and fetch capabilities",
                    label: "宾语",
                    note: "名词短语，表示连接的对象"
                ),
                GrammarChunk(id: "adv", role: .adv, text: coarseAdverbial, label: "结果状语", note: "现在分词短语作结果状语")
            ],
            in: source
        )

        try check(
            chunks.map(\.text) == [
                "Search and Fetch",
                "connects to",
                "PatSnap patent and paper search and fetch capabilities",
                "allowing",
                "the AI assistant",
                "to search for relevant records",
                "and retrieve detailed information for selected items"
            ],
            "adverbial regression should split the oversized allowing phrase into smaller chunks"
        )
        try check(!chunks.contains { $0.text == coarseAdverbial }, "adverbial regression should not keep the coarse allowing phrase")

        return GrammarResult(
            title: "语法解析",
            sourceSentence: source,
            chineseMeaning: "Search and Fetch 连接到 PatSnap 的专利和论文搜索与获取功能，使 AI 助手能够搜索相关记录并检索选定项目的详细信息。",
            analysisScopeNote: "回归用例：现在分词结果状语需要拆成内部对象和并列动作。",
            chunks: chunks,
            dependencies: [
                GrammarDependency(from: "v", to: "s", label: "主谓"),
                GrammarDependency(from: "v", to: "o", label: "动宾"),
                GrammarDependency(from: "adv-adv", to: "adv-object", label: "使役对象"),
                GrammarDependency(from: "adv-adv", to: "adv-action-1", label: "补足动作"),
                GrammarDependency(from: "adv-action-1", to: "adv-action-2", label: "并列动作")
            ],
            tree: GrammarTreeNode(
                label: "主句",
                role: .predicate,
                text: "Search and Fetch connects to ...",
                children: [
                    GrammarTreeNode(label: "主语", role: .subject, text: "Search and Fetch"),
                    GrammarTreeNode(label: "谓语", role: .predicate, text: "connects to"),
                    GrammarTreeNode(label: "宾语", role: .object, text: "PatSnap patent and paper search and fetch capabilities"),
                    GrammarTreeNode(
                        label: "结果状语",
                        role: .adv,
                        text: "allowing ...",
                        children: [
                            GrammarTreeNode(label: "非谓语", role: .adv, text: "allowing"),
                            GrammarTreeNode(label: "内部宾语", role: .object, text: "the AI assistant"),
                            GrammarTreeNode(label: "不定式动作", role: .predicate, text: "to search for relevant records"),
                            GrammarTreeNode(label: "并列动作", role: .predicate, text: "and retrieve detailed information for selected items")
                        ]
                    )
                ]
            ),
            trunk: GrammarTrunk(
                core: [
                    GrammarTrunkItem(w: "Search and Fetch", role: .subject),
                    GrammarTrunkItem(w: "connects to", role: .predicate),
                    GrammarTrunkItem(w: "PatSnap capabilities", role: .object)
                ],
                dropped: [
                    "allowing the AI assistant ...（结果状语）"
                ],
                coreZh: "Search and Fetch 连接到 PatSnap 的能力。"
            ),
            tenseVoice: [
                GrammarTenseClause(
                    scope: "主句",
                    verb: "connects to",
                    tense: "一般现在时",
                    aspect: "一般体",
                    voice: "主动",
                    mood: "陈述",
                    why: "一般现在时描述产品能力或事实。",
                    svo: GrammarSVO(agent: "Search and Fetch", action: "connect", receiver: "PatSnap capabilities")
                ),
                GrammarTenseClause(
                    scope: "结果状语",
                    verb: "allowing",
                    tense: "非谓语",
                    aspect: "进行/结果",
                    voice: "主动",
                    mood: "非限定",
                    why: "现在分词说明连接能力带来的结果。",
                    svo: GrammarSVO(agent: "Search and Fetch", action: "allow", receiver: "the AI assistant")
                )
            ],
            wordOrder: GrammarWordOrder(
                en: [
                    GrammarOrderSegment(id: 1, text: "Search and Fetch", role: .subject, zhPos: 1),
                    GrammarOrderSegment(id: 2, text: "connects to", role: .predicate, zhPos: 2),
                    GrammarOrderSegment(id: 3, text: "PatSnap patent and paper search and fetch capabilities", role: .object, zhPos: 3),
                    GrammarOrderSegment(id: 4, text: "allowing", role: .adv, zhPos: 4),
                    GrammarOrderSegment(id: 5, text: "the AI assistant", role: .object, zhPos: 5),
                    GrammarOrderSegment(id: 6, text: "to search for relevant records", role: .predicate, zhPos: 6),
                    GrammarOrderSegment(id: 7, text: "and retrieve detailed information", role: .predicate, zhPos: 7)
                ],
                zhOrder: [1, 2, 3, 4, 5, 6, 7],
                zhText: ["Search and Fetch", "连接到", "PatSnap 能力", "从而允许", "AI 助手", "搜索相关记录", "并检索详细信息"],
                note: "英文结果状语后置，中文可译为“从而/使得”。"
            ),
            pattern: GrammarPattern(en: "S connects to O, allowing A to V and V.", zh: "S 连接到 O，从而允许 A 做两件事。"),
            collocations: [
                GrammarCollocation(phrase: "connect to", pos: "v. phr.", zh: "连接到", note: "说明系统能力或接口连接。", example: "The service connects to the search API."),
                GrammarCollocation(phrase: "search for records", pos: "v. phr.", zh: "搜索记录", note: "for 后接搜索目标。", example: "Users can search for records."),
                GrammarCollocation(phrase: "retrieve information", pos: "v. phr.", zh: "检索信息", note: "常用于数据或文档系统。", example: "The tool retrieves detailed information.")
            ],
            phrases: [
                GrammarPhrase(en: "paper search and fetch capabilities", zh: "论文搜索与获取能力"),
                GrammarPhrase(en: "relevant records", zh: "相关记录"),
                GrammarPhrase(en: "selected items", zh: "选定项目")
            ],
            grammarPoints: [
                GrammarPoint(tag: "非谓语", title: "allowing 作结果状语", body: "现在分词短语说明前面连接能力带来的结果。"),
                GrammarPoint(tag: "修饰", title: "两个不定式动作并列", body: "to search 和 retrieve 共同说明 AI assistant 能做什么。"),
                GrammarPoint(tag: "句型", title: "connects to ..., allowing ...", body: "先给出连接对象，再说明由此产生的能力。")
            ],
            defaultCollectionItem: DefaultCollectionItem(
                title: "S connects to O, allowing A to V and V.",
                note: "S 连接到 O，从而允许 A 做两件事。",
                type: "句型"
            )
        )
    }

    @MainActor
    private static func assertRelativePronounRegressionRenders() throws {
        let fixture = try relativePronounRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "relative pronoun regression should render at panel width")
        try check(image.height > 260, "relative pronoun regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "relative pronoun regression should not be blank")
    }

    @MainActor
    private static func exportRelativePronounRegressionScreenshot(to url: URL) throws {
        let fixture = try relativePronounRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    @MainActor
    private static func relativePronounRegressionFixture() throws -> GrammarResult {
        let source = "The convergence of fashion and high technology is leading to new kinds of fibres, fabrics and coatings that are imbuing clothing with equally wondrous powers."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "s", role: .subject, text: "The convergence of fashion and high technology", label: "主语", note: "抽象名词短语作主语"),
                GrammarChunk(id: "v", role: .predicate, text: "is leading to", label: "谓语", note: "现在进行时谓语"),
                GrammarChunk(id: "o", role: .object, text: "new kinds of fibres, fabrics and coatings", label: "宾语", note: "介词 to 的宾语"),
                GrammarChunk(id: "rel", role: .conj, text: "that", label: "关系代词", note: "引导定语从句"),
                GrammarChunk(id: "rel-s", role: .subject, text: "that", label: "从句主语", note: "that 在定语从句中作主语"),
                GrammarChunk(id: "rel-v", role: .predicate, text: "are imbuing", label: "从句谓语", note: "定语从句谓语"),
                GrammarChunk(id: "rel-o", role: .object, text: "clothing", label: "从句宾语", note: "imbuing 的宾语"),
                GrammarChunk(id: "rel-adv", role: .adv, text: "with equally wondrous powers", label: "内容状语", note: "with 短语说明赋予的内容")
            ],
            in: source
        )
        try check(chunks.filter { $0.text == "that" }.count == 1, "relative pronoun regression should render that once")
        try check(!chunks.map(\.text).joined(separator: " ").contains("that that"), "relative pronoun regression should not duplicate surface text")

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "时尚与高科技的融合正在带来新型纤维、面料和涂层，这些材料赋予服装奇妙能力。",
            analysisScopeNote: "回归用例：关系代词同时作从句主语时只渲染一次。",
            chunks: chunks,
            pattern: GrammarPattern(en: "N that is/are V-ing ...", zh: "正在……的名词")
        )
    }

    @MainActor
    private static func assertColonRecoveryRegressionRenders() throws {
        let fixture = colonRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "colon recovery regression should render at panel width")
        try check(image.height > 260, "colon recovery regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "colon recovery regression should not be blank")
    }

    @MainActor
    private static func exportColonRecoveryRegressionScreenshot(to url: URL) throws {
        let fixture = colonRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    private static func colonRecoveryRegressionFixture() -> GrammarResult {
        let source = "Perpetually by-passing minor cities creates a cycle of disenfranchisement: these cities never get an injection of capital, they fail to become first-rate candidates, and they are constantly passed over in favour of more secure choices."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "lead-s", role: .subject, text: "Perpetually by-passing minor cities", label: "主语", note: "动名词短语作主语"),
                GrammarChunk(id: "lead-v", role: .predicate, text: "creates", label: "谓语", note: "冒号前主句谓语"),
                GrammarChunk(id: "lead-o", role: .object, text: "a cycle of disenfranchisement", label: "宾语", note: "creates 的宾语"),
                GrammarChunk(id: "colon", role: .conj, text: ":", label: "解释连接", note: "冒号引出解释"),
                GrammarChunk(id: "explain-1", role: .appos, text: "these cities never get an injection of capital", label: "解释分句", note: "解释 cycle 的第一层后果"),
                GrammarChunk(id: "explain-2", role: .appos, text: "they fail to become first-rate candidates", label: "并列解释分句", note: "解释 cycle 的第二层后果"),
                GrammarChunk(id: "explain-3", role: .appos, text: "and they are constantly passed over in favour of more secure choices", label: "并列解释分句", note: "解释 cycle 的最终结果")
            ],
            in: source
        )

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "持续绕过小城市会制造被边缘化的循环：这些城市得不到资金注入，也难以成为一流候选地，最终持续被跳过。",
            analysisScopeNote: "回归用例：冒号后的并列解释分句应形成可渲染语法骨架。",
            chunks: chunks,
            pattern: GrammarPattern(en: "S creates N: clause, clause, and clause", zh: "某事造成……：随后用多个分句解释")
        )
    }

    @MainActor
    private static func assertCopularComplementRegressionRenders() throws {
        let fixture = try copularComplementRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "copular complement regression should render at panel width")
        try check(image.height > 260, "copular complement regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "copular complement regression should not be blank")
    }

    @MainActor
    private static func exportCopularComplementRegressionScreenshot(to url: URL) throws {
        let fixture = try copularComplementRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    private static func copularComplementRegressionFixture() throws -> GrammarResult {
        let source = "The feel good factor that most proponents of Olympic bids extol, and that was no doubt driving the approval rates of Parisians and Londoners for their cities' respective bids, can be an elusive phenomenon, and one that is tied to that nation's standing on the medal tables."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "s", role: .subject, text: "The feel good factor", label: "主语", note: "主句主语"),
                GrammarChunk(id: "attr-1", role: .attr, text: "that most proponents of Olympic bids extol", label: "定语从句", note: "修饰 factor"),
                GrammarChunk(id: "attr-2", role: .attr, text: "and that was no doubt driving the approval rates of Parisians and Londoners for their cities' respective bids", label: "并列定语从句", note: "继续修饰 factor"),
                GrammarChunk(id: "v", role: .predicate, text: "can be", label: "谓语", note: "系动词结构"),
                GrammarChunk(id: "c1", role: .object, text: "an elusive phenomenon", label: "宾语", note: "AI 曾误标为宾语"),
                GrammarChunk(id: "c2", role: .object, text: "and one that is tied to that nation's standing on the medal tables", label: "并列宾语", note: "AI 曾误标为第二宾语")
            ],
            in: source
        )
        try check(chunks.first { $0.text == "an elusive phenomenon" }?.role == .appos, "copular complement should normalize to appos role")
        try check(chunks.first { $0.text.hasPrefix("and one") }?.role == .appos, "coordinated copular complement should normalize to appos role")

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "申奥支持者称赞的愉悦感可能是一种难以捉摸的现象，也可能与该国奖牌榜地位相关。",
            analysisScopeNote: "回归用例：系动词 can be 后的成分应作为表语，而不是宾语。",
            chunks: chunks,
            pattern: GrammarPattern(en: "S can be C, and C", zh: "主语可以是某种表语，并且是另一表语")
        )
    }

    @MainActor
    private static func assertInvertedCopularRegressionRenders() throws {
        let fixture = try invertedCopularRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "inverted copular regression should render at panel width")
        try check(image.height > 260, "inverted copular regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "inverted copular regression should not be blank")
    }

    @MainActor
    private static func exportInvertedCopularRegressionScreenshot(to url: URL) throws {
        let fixture = try invertedCopularRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    private static func invertedCopularRegressionFixture() throws -> GrammarResult {
        let source = "Even more confounding than Manet's relaxed attention to detail, however, is the relationship in the painting between the activity in the mirrored reflection and that which we see in the unreflected foreground."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "front", role: .adv, text: "Even more confounding than Manet's relaxed attention to detail", label: "状语", note: "AI 曾误标为状语"),
                GrammarChunk(id: "v", role: .predicate, text: "is", label: "谓语", note: "倒装系动词"),
                GrammarChunk(id: "place", role: .adv, text: "in the painting", label: "地点状语", note: "AI 输出中保留的局部短语"),
                GrammarChunk(id: "mirror", role: .adv, text: "in the mirrored reflection", label: "地点状语", note: "AI 输出中保留的局部短语"),
                GrammarChunk(id: "relative", role: .attr, text: "that which we see in the unreflected foreground", label: "定语从句", note: "修饰 activity/that")
            ],
            in: source
        )
        try check(chunks.first?.role == .appos, "inverted copular fronted complement should render as complement")
        try check(chunks.contains { $0.role == .subject && $0.text.contains("the relationship") && $0.text.contains("the activity") }, "inverted copular subject should be restored")

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "更令人困惑的是画中镜面反射活动与未反射前景中所见内容之间的关系。",
            analysisScopeNote: "回归用例：倒装系表结构应保留后置主语的核心词。",
            chunks: chunks,
            pattern: GrammarPattern(en: "C, however, is S", zh: "表语前置，主语后置")
        )
    }

    @MainActor
    private static func assertLongSchemaRecoveryRegressionRenders() throws {
        let fixture = longSchemaRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "long schema recovery regression should render at panel width")
        try check(image.height > 260, "long schema recovery regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "long schema recovery regression should not be blank")
    }

    @MainActor
    private static func exportLongSchemaRecoveryRegressionScreenshot(to url: URL) throws {
        let fixture = longSchemaRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    private static func longSchemaRecoveryRegressionFixture() -> GrammarResult {
        let source = "Davis was also frustrated by his perception that he had been overlooked by the music critics, who were hailing the success of his collaborators and descendants in the cool tradition, but who afforded him little credit for introducing the cool sound in the first place."
        let chunks = GrammarResult.normalizedChunks(
            [
                GrammarChunk(id: "s", role: .subject, text: "Davis", label: "主语", note: "句子主语"),
                GrammarChunk(id: "v", role: .predicate, text: "was also frustrated", label: "系表谓语", note: "被动/系表结构说明状态"),
                GrammarChunk(id: "cause", role: .adv, text: "by his perception", label: "原因状语", note: "说明沮丧来源"),
                GrammarChunk(id: "content", role: .attr, text: "that he had been overlooked by the music critics", label: "内容从句", note: "说明 perception 的内容"),
                GrammarChunk(id: "rel-1", role: .attr, text: "who were hailing the success of his collaborators and descendants in the cool tradition", label: "定语从句", note: "修饰 critics"),
                GrammarChunk(id: "rel-2", role: .attr, text: "but who afforded him little credit for introducing the cool sound in the first place", label: "并列定语从句", note: "继续修饰 critics")
            ],
            in: source
        )

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "Davis 也因自己认为被乐评人忽视而感到沮丧；这些乐评人赞扬了他的合作者和后辈，却很少认可他最初引入 cool sound 的贡献。",
            analysisScopeNote: "回归用例：长句 schema drift 后仍应能展示可恢复语法骨架。",
            chunks: chunks,
            pattern: GrammarPattern(en: "S was frustrated by N that ..., who ..., but who ...", zh: "主语因某种认知而沮丧，后接内容从句和并列定语从句")
        )
    }

    @MainActor
    private static func assertPassiveContrastRecoveryRegressionRenders() throws {
        let fixture = try passiveContrastRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        try check(image.width >= 700, "passive-contrast recovery regression should render at panel width")
        try check(image.height > 260, "passive-contrast recovery regression should render real content")
        try check(visiblePixelCount(in: image) > 800, "passive-contrast recovery regression should not be blank")
    }

    @MainActor
    private static func exportPassiveContrastRecoveryRegressionScreenshot(to url: URL) throws {
        let fixture = try passiveContrastRecoveryRegressionFixture()
        let image = try renderImage(for: fixture, tab: .annotated)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 760))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    private static func passiveContrastRecoveryRegressionFixture() throws -> GrammarResult {
        let source = "The staggering expenses involved in a successful Olympic bid are often assumed to be easily mitigated by tourist revenues and an increase in local employment, but more often than not host cities are short changed and their taxpayers for generations to come are left settling the debt."
        let chunks = GrammarResult.recoveryChunks(for: source)
        try check(chunks.contains { $0.text == "are often assumed to be easily mitigated" && $0.role == .predicate }, "passive-contrast fixture should include the main passive predicate")
        try check(chunks.contains { $0.text == "host cities" && $0.role == .subject }, "passive-contrast fixture should include the first contrast subject")
        try check(chunks.contains { $0.text == "are short changed" && $0.role == .predicate }, "passive-contrast fixture should include the first contrast predicate")
        try check(chunks.contains { $0.text == "their taxpayers for generations to come" && $0.role == .subject }, "passive-contrast fixture should include the second contrast subject")
        try check(chunks.contains { $0.text == "are left settling" && $0.role == .predicate }, "passive-contrast fixture should include the second contrast predicate")
        try check(chunks.contains { $0.text == "the debt" && $0.role == .object }, "passive-contrast fixture should include the settling object")

        return regressionGrammarResult(
            source: source,
            chineseMeaning: "成功申奥的巨额费用常被认为能由旅游收入和就业增长轻易抵消，但主办城市往往吃亏，纳税人还要长期偿还债务。",
            analysisScopeNote: "回归用例：AI 首次未返回 JSON 时，应恢复被动主句和转折并列被动分句，而不是显示 schema 错误。",
            chunks: chunks,
            pattern: GrammarPattern(en: "Passive S V, but Adv S V and S V-ing O", zh: "被动主句后接转折并列被动分句")
        )
    }

    private static func regressionGrammarResult(
        source: String,
        chineseMeaning: String,
        analysisScopeNote: String,
        chunks: [GrammarChunk],
        pattern: GrammarPattern
    ) -> GrammarResult {
        GrammarResult(
            title: "语法解析",
            sourceSentence: source,
            chineseMeaning: chineseMeaning,
            analysisScopeNote: analysisScopeNote,
            chunks: chunks,
            dependencies: [],
            tree: GrammarTreeNode(
                label: "主句",
                role: .predicate,
                text: source,
                children: chunks.map { GrammarTreeNode(label: $0.label, role: $0.role, text: $0.text) }
            ),
            trunk: GrammarTrunk(
                core: chunks
                    .filter { [.subject, .predicate, .object].contains($0.role) }
                    .map { GrammarTrunkItem(w: $0.text, role: $0.role) },
                dropped: chunks
                    .filter { ![.subject, .predicate, .object].contains($0.role) }
                    .map { "\($0.text)（\($0.label)）" },
                coreZh: chineseMeaning
            ),
            tenseVoice: [],
            wordOrder: GrammarWordOrder(
                en: chunks.enumerated().map { index, chunk in
                    GrammarOrderSegment(id: index + 1, text: chunk.text, role: chunk.role, zhPos: index + 1)
                },
                zhOrder: chunks.indices.map { $0 + 1 },
                zhText: chunks.map(\.label),
                note: "回归 fixture 的语序骨架。"
            ),
            pattern: pattern,
            collocations: [],
            phrases: [],
            grammarPoints: [],
            defaultCollectionItem: DefaultCollectionItem(title: pattern.en, note: pattern.zh, type: "句型")
        )
    }

    @MainActor
    private static func assertNativeDependencyRegressionRenders() throws {
        let fixture = nativeDependencyRegressionFixture()
        let image = try renderImage(for: fixture, tab: .dependency)
        try check(image.width >= 700, "native dependency regression tab should render at panel width")
        try check(image.height > 260, "native dependency regression tab should render real content")
        try check(visiblePixelCount(in: image) > 800, "native dependency regression tab should not be blank")
    }

    @MainActor
    private static func exportNativeDependencyRegressionScreenshot(to url: URL) throws {
        let fixture = nativeDependencyRegressionFixture()
        let image = try renderImage(for: fixture, tab: .dependency)
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 520))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    @MainActor
    private static func assertDependencyHoverRegressionRenders() throws {
        let fixture = nativeDependencyRegressionFixture()
        let defaultImage = try renderImage(for: fixture, tab: .dependency)
        let hoverImage = try renderImage(for: fixture, tab: .dependency, initialDependencyHoveredChunkID: "native")
        try check(hoverImage.width >= 700, "dependency hover regression tab should render at panel width")
        try check(hoverImage.height > 260, "dependency hover regression tab should render real content")
        try check(visiblePixelCount(in: hoverImage) > 800, "dependency hover regression tab should not be blank")
        try check(differentPixelCount(defaultImage, hoverImage) > 400, "dependency hover regression should visibly differ from default state")

        for dependency in fixture.dependencies {
            let dependencyHoverImage = try renderImage(
                for: fixture,
                tab: .dependency,
                initialDependencyHoveredDependencyID: dependency.id
            )
            try check(
                differentPixelCount(defaultImage, dependencyHoverImage) > 250,
                "dependency line hover should visibly differ from default state for \(dependency.id)"
            )
        }
    }

    @MainActor
    private static func exportDependencyHoverRegressionScreenshot(to url: URL) throws {
        let fixture = nativeDependencyRegressionFixture()
        let image = try renderImage(for: fixture, tab: .dependency, initialDependencyHoveredChunkID: "native")
        let focusedRect = CGRect(x: 0, y: 0, width: image.width, height: min(image.height, 520))
        try writePNG(image.cropping(to: focusedRect) ?? image, to: url)
    }

    @MainActor
    private static func exportDependencyHoverMatrixScreenshot(to url: URL) throws {
        let fixture = nativeDependencyRegressionFixture()
        let images = try fixture.dependencies.map { dependency in
            let image = try renderImage(
                for: fixture,
                tab: .dependency,
                initialDependencyHoveredDependencyID: dependency.id
            )
            let focusedRect = CGRect(x: 0, y: 210, width: image.width, height: min(310, image.height - 210))
            return image.cropping(to: focusedRect) ?? image
        }
        let matrix = try makeImageMatrix(images, columns: 3, gap: 10, background: CGColor(red: 28 / 255, green: 30 / 255, blue: 40 / 255, alpha: 1))
        try writePNG(matrix, to: url)
        print("Dependency hover lines tested: \(fixture.dependencies.map(\.id).joined(separator: ", "))")
    }

    private static func nativeDependencyRegressionFixture() -> GrammarResult {
        let source = "A free, open-source GUI for the Mole (mo) engine — now bundled in the app, so there is nothing else to install. Clean, uninstall, optimize, analyze disk, and watch live system status, long-range history and local MCP access for AI agents. Native on macOS, with a Windows preview implemented under windows/."
        return GrammarResult(
            title: "语法解析",
            sourceSentence: source,
            chineseMeaning: "一个免费的开源 Mole 引擎图形界面，现在已集成到应用中，无需额外安装；可清理、卸载、优化、分析磁盘并查看实时系统状态、长期历史和本地 MCP 访问；macOS 原生，并有 Windows 预览。",
            analysisScopeNote: "回归用例：密集依存关系标签应避让，不应互相重叠。",
            chunks: [
                GrammarChunk(id: "s", role: .subject, text: "A free, open-source GUI for the Mole (mo) engine", label: "主语", note: "名词短语作主语"),
                GrammarChunk(id: "v", role: .predicate, text: "is bundled in the app", label: "谓语", note: "被动谓语，说明已集成到应用中"),
                GrammarChunk(id: "adv", role: .adv, text: "now", label: "时间状语", note: "说明当前状态"),
                GrammarChunk(id: "so", role: .conj, text: "so", label: "连接词", note: "引出结果"),
                GrammarChunk(id: "there", role: .subject, text: "there", label: "形式主语", note: "there be 结构中的形式主语"),
                GrammarChunk(id: "install", role: .predicate, text: "is nothing else to install", label: "谓语", note: "说明无需额外安装"),
                GrammarChunk(id: "actions", role: .predicate, text: "Clean, uninstall, optimize, analyze disk, and watch live system status", label: "并列谓语", note: "列出可执行动作"),
                GrammarChunk(id: "access", role: .object, text: "long-range history and local MCP access for AI agents", label: "宾语", note: "动作覆盖的对象和能力"),
                GrammarChunk(id: "native", role: .predicate, text: "Native on macOS", label: "形容词短语", note: "标题式省略结构，表示 macOS 原生"),
                GrammarChunk(id: "windows", role: .adv, text: "with a Windows preview implemented under windows/", label: "介词短语", note: "补充说明 Windows 预览位置")
            ],
            dependencies: [
                GrammarDependency(from: "v", to: "s", label: "主谓"),
                GrammarDependency(from: "v", to: "adv", label: "修饰"),
                GrammarDependency(from: "so", to: "install", label: "连接"),
                GrammarDependency(from: "install", to: "there", label: "主谓"),
                GrammarDependency(from: "v", to: "install", label: "结果"),
                GrammarDependency(from: "actions", to: "access", label: "动宾"),
                GrammarDependency(from: "actions", to: "native", label: "连接"),
                GrammarDependency(from: "native", to: "windows", label: "连接"),
                GrammarDependency(from: "windows", to: "native", label: "修饰")
            ],
            tree: GrammarTreeNode(
                label: "复合说明句",
                role: .predicate,
                text: source,
                children: [
                    GrammarTreeNode(label: "主语", role: .subject, text: "A free, open-source GUI for the Mole (mo) engine"),
                    GrammarTreeNode(label: "谓语", role: .predicate, text: "is bundled in the app"),
                    GrammarTreeNode(label: "结果分句", role: .predicate, text: "so there is nothing else to install"),
                    GrammarTreeNode(label: "功能列表", role: .predicate, text: "Clean, uninstall, optimize, analyze disk, and watch ..."),
                    GrammarTreeNode(label: "平台补充", role: .predicate, text: "Native on macOS, with a Windows preview ...")
                ]
            ),
            trunk: GrammarTrunk(
                core: [
                    GrammarTrunkItem(w: "A GUI", role: .subject),
                    GrammarTrunkItem(w: "is bundled", role: .predicate),
                    GrammarTrunkItem(w: "features", role: .object)
                ],
                dropped: [
                    "now（时间状语）",
                    "so there is nothing else to install（结果分句）",
                    "Native on macOS（平台补充）",
                    "with a Windows preview implemented under windows/（补充说明）"
                ],
                coreZh: "这个 GUI 已集成，并提供多种管理能力。"
            ),
            tenseVoice: [
                GrammarTenseClause(
                    scope: "主句",
                    verb: "is bundled",
                    tense: "一般现在时",
                    aspect: "一般体",
                    voice: "被动",
                    mood: "陈述",
                    why: "被动语态强调 GUI 已被集成到应用里。",
                    svo: GrammarSVO(agent: "(the app)", action: "bundle", receiver: "A GUI")
                )
            ],
            wordOrder: GrammarWordOrder(
                en: [
                    GrammarOrderSegment(id: 1, text: "A free GUI", role: .subject, zhPos: 1),
                    GrammarOrderSegment(id: 2, text: "is bundled in the app", role: .predicate, zhPos: 2),
                    GrammarOrderSegment(id: 3, text: "so there is nothing else to install", role: .predicate, zhPos: 3),
                    GrammarOrderSegment(id: 4, text: "Native on macOS", role: .predicate, zhPos: 4),
                    GrammarOrderSegment(id: 5, text: "with a Windows preview", role: .adv, zhPos: 5)
                ],
                zhOrder: [1, 2, 3, 4, 5],
                zhText: ["一个免费 GUI", "已集成到应用中", "因此无需额外安装", "macOS 原生", "并带 Windows 预览"],
                note: "中文可以按信息顺序顺译，并把平台补充放在后面。"
            ),
            pattern: GrammarPattern(en: "Subject + Predicate + Adverbial + Conjunction + Clause", zh: "主语 + 谓语 + 状语 + 连接词 + 分句"),
            collocations: [
                GrammarCollocation(phrase: "native on macOS", pos: "adj. phr.", zh: "macOS 原生", note: "表示在 macOS 上原生运行。", example: "This app is native on macOS."),
                GrammarCollocation(phrase: "implemented under", pos: "v. phr.", zh: "在……下实现", note: "说明实现位置。", example: "The preview is implemented under windows/."),
                GrammarCollocation(phrase: "Windows preview", pos: "n. phr.", zh: "Windows 预览版", note: "预览或实验版本。", example: "The Windows preview is available.")
            ],
            phrases: [
                GrammarPhrase(en: "Native on macOS", zh: "macOS 原生"),
                GrammarPhrase(en: "Windows preview", zh: "Windows 预览版"),
                GrammarPhrase(en: "under windows/", zh: "在 windows/ 目录下")
            ],
            grammarPoints: [
                GrammarPoint(tag: "修饰", title: "介词短语作表语补充", body: "on macOS 补充 Native 的适用平台。"),
                GrammarPoint(tag: "从句", title: "过去分词短语后置", body: "implemented under windows/ 修饰 Windows preview。"),
                GrammarPoint(tag: "句型", title: "标题式省略结构", body: "省略主语和 be 动词，保留信息密度。")
            ],
            defaultCollectionItem: DefaultCollectionItem(
                title: "Adj + PrepPhrase, + PrepPhrase",
                note: "形容词 + 介词短语，+ 介词短语",
                type: "句型"
            )
        )
    }

    @MainActor
    private static func runBenchmarks() async throws {
        let iterations = 8
        print("Grammar benchmark iterations: \(iterations)")

        for fixture in GrammarResult.grammarUITestFixtures {
            let encoded = try JSONEncoder().encode(fixture)
            let decoded = try measureAverage(iterations: iterations * 50) {
                _ = try JSONDecoder().decode(GrammarResult.self, from: encoded)
            }

            print("")
            print("Fixture: \(fixture.sourceSentence.prefix(72))")
            print("Payload: \(encoded.count) bytes, chunks=\(fixture.chunks.count), deps=\(fixture.dependencies.count), treeNodes=\(flattenTree(fixture.tree).count), tokens=\(fixture.chunks.reduce(0) { $0 + $1.tokens.count })")
            print(String(format: "Decode avg: %.3f ms", decoded))

            let stubbedCompletion = try await runStubbedCompletionBenchmark(fixture: fixture, iterations: iterations * 20)
            print(String(format: "Stub client + extract + decode avg: %.3f ms", stubbedCompletion))

            for tab in GrammarVizView.allCases {
                let average = try measureAverage(iterations: iterations) {
                    _ = try renderImage(for: fixture, tab: tab)
                }
                print(String(format: "Render \(padded(tab.rawValue, to: 10)) %.3f ms", average))
            }
        }
    }

    nonisolated private static func runStubbedCompletionBenchmark(
        fixture: GrammarResult,
        iterations: Int
    ) async throws -> Double {
        let responseData = try stubbedChatCompletionData(for: fixture)
        GrammarStubURLProtocol.responseData = responseData

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GrammarStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = OpenAICompatibleClient(
            configuration: AIProviderConfiguration(
                apiToken: "benchmark-token",
                baseURLString: "https://benchmark.invalid/v1",
                model: "benchmark-model"
            ),
            urlSession: session
        )

        return try await measureAverageAsync(iterations: iterations) {
            let completion = try await client.complete(system: "benchmark", user: fixture.sourceSentence)
            let json = try StructuredJSONExtractor.extractObject(from: completion)
            _ = try JSONDecoder().decode(GrammarResult.self, from: Data(json.utf8))
        }
    }

    nonisolated private static func stubbedChatCompletionData(for fixture: GrammarResult) throws -> Data {
        let payload = try JSONEncoder().encode(fixture)
        let content = String(decoding: payload, as: UTF8.self)
        let response: [String: Any] = [
            "choices": [
                [
                    "message": [
                        "role": "assistant",
                        "content": content
                    ]
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: response)
    }

    @MainActor
    private static func renderImage(
        for fixture: GrammarResult,
        tab: GrammarVizView,
        initialDependencyHoveredChunkID: String? = nil,
        initialDependencyHoveredDependencyID: String? = nil
    ) throws -> CGImage {
        let content = GrammarResultPanel(
            result: fixture,
            initialView: tab,
            initialDependencyHoveredChunkID: initialDependencyHoveredChunkID,
            initialDependencyHoveredDependencyID: initialDependencyHoveredDependencyID
        )
            .frame(width: 720)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(red: 28 / 255, green: 30 / 255, blue: 40 / 255))
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 720, height: nil)

        guard let image = renderer.cgImage else {
            throw GrammarUICheckFailure.failed("\(fixture.sourceSentence) \(tab.rawValue) should render a CGImage")
        }
        return image
    }

    private static func measureAverage(iterations: Int, _ operation: () throws -> Void) rethrows -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            try operation()
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        return Double(elapsed) / Double(iterations) / 1_000_000
    }

    nonisolated private static func measureAverageAsync(
        iterations: Int,
        _ operation: () async throws -> Void
    ) async rethrows -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            try await operation()
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        return Double(elapsed) / Double(iterations) / 1_000_000
    }

    private static func flattenTree(_ node: GrammarTreeNode) -> [GrammarTreeNode] {
        [node] + node.children.flatMap(flattenTree)
    }

    private static func padded(_ text: String, to width: Int) -> String {
        text + String(repeating: " ", count: max(width - text.count, 0))
    }

    private static func visiblePixelCount(in image: CGImage) -> Int {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 3, to: pixels.count, by: bytesPerPixel).reduce(into: 0) { count, alphaIndex in
            if pixels[alphaIndex] > 8 {
                count += 1
            }
        }
    }

    private static func differentPixelCount(_ lhs: CGImage, _ rhs: CGImage) -> Int {
        guard lhs.width == rhs.width, lhs.height == rhs.height,
              let lhsPixels = rgbaPixels(in: lhs),
              let rhsPixels = rgbaPixels(in: rhs) else {
            return 0
        }

        return stride(from: 0, to: lhsPixels.count, by: 4).reduce(into: 0) { count, index in
            let redDelta = abs(Int(lhsPixels[index]) - Int(rhsPixels[index]))
            let greenDelta = abs(Int(lhsPixels[index + 1]) - Int(rhsPixels[index + 1]))
            let blueDelta = abs(Int(lhsPixels[index + 2]) - Int(rhsPixels[index + 2]))
            let alphaDelta = abs(Int(lhsPixels[index + 3]) - Int(rhsPixels[index + 3]))
            if redDelta + greenDelta + blueDelta + alphaDelta > 24 {
                count += 1
            }
        }
    }

    private static func rgbaPixels(in image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private static func makeImageMatrix(
        _ images: [CGImage],
        columns: Int,
        gap: Int,
        background: CGColor
    ) throws -> CGImage {
        guard !images.isEmpty, columns > 0 else {
            throw GrammarUICheckFailure.failed("image matrix requires at least one image and one column")
        }

        let cellWidth = images.map(\.width).max() ?? 1
        let cellHeight = images.map(\.height).max() ?? 1
        let rows = Int(ceil(Double(images.count) / Double(columns)))
        let width = columns * cellWidth + max(columns - 1, 0) * gap
        let height = rows * cellHeight + max(rows - 1, 0) * gap
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw GrammarUICheckFailure.failed("could not create image matrix context")
        }

        context.setFillColor(background)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for (index, image) in images.enumerated() {
            let column = index % columns
            let row = index / columns
            let x = column * (cellWidth + gap)
            let y = height - (row + 1) * cellHeight - row * gap
            context.draw(image, in: CGRect(x: x, y: y, width: image.width, height: image.height))
        }

        guard let image = context.makeImage() else {
            throw GrammarUICheckFailure.failed("could not create image matrix")
        }
        return image
    }

    private static func requestedOverlapScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-overlap-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedAdverbialScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-adverbial-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedNativeDependencyScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-native-dependency-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedDependencyHoverScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-dependency-hover-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedDependencyHoverMatrixScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-dependency-hover-matrix-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedRelativePronounScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-relative-pronoun-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedColonRecoveryScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-colon-recovery-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedCopularComplementScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-copular-complement-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedInvertedCopularScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-inverted-copular-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedLongSchemaRecoveryScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-long-schema-recovery-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func requestedPassiveContrastRecoveryScreenshotURL() -> URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--write-passive-contrast-recovery-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: CommandLine.arguments[index + 1])
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw GrammarUICheckFailure.failed("could not create PNG destination")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw GrammarUICheckFailure.failed("could not write PNG")
        }
    }
}

private final class GrammarStubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://benchmark.invalid/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
