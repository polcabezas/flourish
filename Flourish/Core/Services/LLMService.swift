import Foundation

// MARK: - LLM Service Protocol

protocol LLMService {
    func improvePrompt(
        _ text: String,
        systemPrompt: String,
        model: String
    ) async throws -> LLMResponse
}

// MARK: - Response

struct LLMResponse {
    let improvedText: String
    let tokensIn: Int
    let tokensOut: Int
    let modelId: String
    let provider: LLMProvider
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case emptyInput
    case badRequest(String)
    case unauthorized
    case billingError
    case rateLimited
    case serverError(Int)
    case invalidResponse
    case noContent

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Prompt is empty."
        case .badRequest(let msg):
            return "Bad request: \(msg)"
        case .unauthorized:
            return "Authorization failed. Please contact support."
        case .billingError:
            return "Service billing issue. Please contact support."
        case .rateLimited:
            return "Rate limit reached. Wait a moment and try again."
        case .serverError(let code):
            return "Server error (\(code)). The service may be temporarily unavailable."
        case .invalidResponse:
            return "Unexpected response format from the API."
        case .noContent:
            return "The model returned an empty response."
        }
    }
}

// MARK: - Shared OpenAI-Compatible Response Types

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
    let model: String?

    struct Choice: Codable {
        let message: Message
        struct Message: Codable {
            let content: String?
        }
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
        }
    }
}

struct ChatCompletionError: Codable {
    let error: ErrorBody?
    struct ErrorBody: Codable {
        let message: String?
    }
}
