import Foundation

public enum DeepSeekError: LocalizedError, Equatable, Sendable {
    case missingAPIKey
    case invalidResponse
    case server(statusCode: Int, message: String)
    case emptyCompletion

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "DeepSeek API key is missing."
        case .invalidResponse:
            "DeepSeek returned an invalid response."
        case .server(let statusCode, let message):
            "DeepSeek request failed with HTTP \(statusCode): \(message)"
        case .emptyCompletion:
            "DeepSeek returned an empty completion."
        }
    }
}

public struct DeepSeekClient: Sendable {
    public var baseURL: URL
    public var apiKey: String
    public var model: String
    public var urlSession: URLSession

    public init(
        baseURL: URL = URL(string: "https://api.deepseek.com")!,
        apiKey: String,
        model: String = "deepseek-v4-flash",
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.urlSession = urlSession
    }

    public func complete(system: String, user: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepSeekError.missingAPIKey
        }

        let request = try DeepSeekRequestFactory.request(
            baseURL: baseURL,
            apiKey: apiKey,
            model: model,
            system: system,
            user: user
        )
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw DeepSeekError.server(statusCode: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepSeekError.emptyCompletion
        }
        return content
    }
}

public enum DeepSeekRequestFactory {
    public static func request(
        baseURL: URL,
        apiKey: String,
        model: String,
        system: String,
        user: String
    ) throws -> URLRequest {
        let endpoint = baseURL.appending(path: "chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = DeepSeekChatRequest(
            model: model,
            messages: [
                DeepSeekMessage(role: "system", content: system),
                DeepSeekMessage(role: "user", content: user)
            ],
            temperature: 0.2,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}

public struct DeepSeekChatRequest: Codable, Equatable, Sendable {
    public var model: String
    public var messages: [DeepSeekMessage]
    public var temperature: Double
    public var stream: Bool

    public init(model: String, messages: [DeepSeekMessage], temperature: Double, stream: Bool) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.stream = stream
    }
}

public struct DeepSeekMessage: Codable, Equatable, Sendable {
    public var role: String
    public var content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct DeepSeekChatResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: DeepSeekMessage
    }
}
