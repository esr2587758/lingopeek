import Foundation

public struct AIProviderConfiguration: Equatable, Sendable {
    public var apiToken: String
    public var baseURLString: String
    public var model: String

    public init(apiToken: String, baseURLString: String, model: String) {
        self.apiToken = apiToken
        self.baseURLString = baseURLString
        self.model = model
    }

    public var isUsable: Bool {
        !normalizedAPIToken.isEmpty && normalizedBaseURL != nil && !normalizedModel.isEmpty
    }

    public var normalizedAPIToken: String {
        apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var normalizedBaseURL: URL? {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }

    public var normalizedModel: String {
        model.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
