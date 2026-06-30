import Foundation

public enum OpenAICompatibleError: LocalizedError, Equatable, Sendable {
    case unusableConfiguration
    case invalidResponse
    case server(statusCode: Int, message: String)
    case emptyCompletion

    public var errorDescription: String? {
        switch self {
        case .unusableConfiguration:
            "AI provider configuration is incomplete."
        case .invalidResponse:
            "AI provider returned an invalid response."
        case .server(let statusCode, let message):
            "AI provider request failed with HTTP \(statusCode): \(message)"
        case .emptyCompletion:
            "AI provider returned an empty completion."
        }
    }
}

public struct OpenAICompatibleClient: Sendable {
    public var configuration: AIProviderConfiguration
    public var urlSession: URLSession

    public init(configuration: AIProviderConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    public func complete(system: String, user: String, maxTokens: Int = 4096) async throws -> String {
        let request = try OpenAICompatibleRequestFactory.request(
            configuration: configuration,
            system: system,
            user: user,
            maxTokens: maxTokens
        )
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAICompatibleError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw OpenAICompatibleError.server(statusCode: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAICompatibleError.emptyCompletion
        }
        return content
    }

    public func testConnection() async throws -> String {
        let request = try OpenAICompatibleRequestFactory.connectivityTestRequest(configuration: configuration)
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAICompatibleError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw OpenAICompatibleError.server(statusCode: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAICompatibleError.emptyCompletion
        }
        return content
    }
}

public enum OpenAICompatibleRequestFactory {
    public static func request(
        configuration: AIProviderConfiguration,
        system: String,
        user: String,
        maxTokens: Int = 4096
    ) throws -> URLRequest {
        guard configuration.isUsable,
              let baseURL = configuration.normalizedBaseURL else {
            throw OpenAICompatibleError.unusableConfiguration
        }

        let endpoint = baseURL.appending(path: "chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.normalizedAPIToken)", forHTTPHeaderField: "Authorization")

        let body = OpenAIChatRequest(
            model: configuration.normalizedModel,
            messages: [
                OpenAIMessage(role: "system", content: system),
                OpenAIMessage(role: "user", content: user)
            ],
            temperature: 0.2,
            maxTokens: maxTokens,
            responseFormat: OpenAIResponseFormat(type: "json_object"),
            thinking: thinkingConfiguration(for: configuration),
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    public static func connectivityTestRequest(
        configuration: AIProviderConfiguration
    ) throws -> URLRequest {
        guard configuration.isUsable,
              let baseURL = configuration.normalizedBaseURL else {
            throw OpenAICompatibleError.unusableConfiguration
        }

        let endpoint = baseURL.appending(path: "chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.normalizedAPIToken)", forHTTPHeaderField: "Authorization")

        let body = OpenAIChatRequest(
            model: configuration.normalizedModel,
            messages: [
                OpenAIMessage(role: "system", content: "Reply with exactly: pong"),
                OpenAIMessage(role: "user", content: "ping")
            ],
            temperature: 0,
            maxTokens: 8,
            responseFormat: nil,
            thinking: nil,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private static func thinkingConfiguration(for configuration: AIProviderConfiguration) -> OpenAIThinkingConfig? {
        let model = configuration.normalizedModel.lowercased()
        guard model.hasPrefix("deepseek-v4") else {
            return nil
        }
        return OpenAIThinkingConfig(type: "disabled")
    }
}

public struct OpenAIChatRequest: Codable, Equatable, Sendable {
    public var model: String
    public var messages: [OpenAIMessage]
    public var temperature: Double
    public var maxTokens: Int?
    public var responseFormat: OpenAIResponseFormat?
    public var thinking: OpenAIThinkingConfig?
    public var stream: Bool

    public init(
        model: String,
        messages: [OpenAIMessage],
        temperature: Double,
        maxTokens: Int? = nil,
        responseFormat: OpenAIResponseFormat? = nil,
        thinking: OpenAIThinkingConfig? = nil,
        stream: Bool
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.responseFormat = responseFormat
        self.thinking = thinking
        self.stream = stream
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
        case thinking
        case stream
    }
}

public struct OpenAIResponseFormat: Codable, Equatable, Sendable {
    public var type: String

    public init(type: String) {
        self.type = type
    }
}

public struct OpenAIThinkingConfig: Codable, Equatable, Sendable {
    public var type: String

    public init(type: String) {
        self.type = type
    }
}

public struct OpenAIMessage: Codable, Equatable, Sendable {
    public var role: String
    public var content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct OpenAIChatResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: OpenAIMessage
    }
}
