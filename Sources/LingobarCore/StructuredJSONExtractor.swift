import Foundation

public enum StructuredJSONExtractor {
    public static func extractObject(from text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{"), trimmed.hasSuffix("}") {
            return trimmed
        }

        if let fenced = fencedJSON(in: trimmed) {
            return fenced
        }

        if let object = firstJSONObject(in: trimmed) {
            return object
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "No JSON object found in AI response")
        )
    }

    private static func fencedJSON(in text: String) -> String? {
        guard let fenceStart = text.range(of: "```") else {
            return nil
        }
        let afterFence = text[fenceStart.upperBound...]
        let contentStart: String.Index
        if let newline = afterFence.firstIndex(of: "\n") {
            contentStart = afterFence.index(after: newline)
        } else {
            contentStart = afterFence.startIndex
        }
        guard let fenceEnd = afterFence[contentStart...].range(of: "```") else {
            return nil
        }
        let fenced = String(afterFence[contentStart..<fenceEnd.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return fenced.isEmpty ? nil : fenced
    }

    private static func firstJSONObject(in text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else {
            return nil
        }

        var depth = 0
        var isInString = false
        var isEscaped = false
        var index = start

        while index < text.endIndex {
            let character = text[index]
            if isInString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }
            } else if character == "\"" {
                isInString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return String(text[start...index])
                }
            }
            index = text.index(after: index)
        }

        return nil
    }
}
