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
    static func main() {
        do {
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
