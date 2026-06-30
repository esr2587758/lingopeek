import CoreGraphics
import Foundation
import LingobarCore
import LingobarUI
import SwiftUI

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
    private static func renderImage(for fixture: GrammarResult, tab: GrammarVizView) throws -> CGImage {
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
