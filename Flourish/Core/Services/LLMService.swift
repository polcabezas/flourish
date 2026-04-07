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
    case monthlyLimitReached(plan: String, limit: Int)
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
            return "Sign in to use flourish."
        case .billingError:
            return "Service billing issue. Please contact support."
        case .rateLimited:
            return "Rate limit reached. Wait a moment and try again."
        case .monthlyLimitReached(let plan, let limit):
            return "You've used all \(limit) requests on the \(plan) plan this month. Upgrade to continue."
        case .serverError(let code):
            return "Server error (\(code)). The service may be temporarily unavailable."
        case .invalidResponse:
            return "Unexpected response format from the API."
        case .noContent:
            return "The model returned an empty response."
        }
    }
}

// MARK: - Worker Limit Error (decoded from 429 response body)

struct WorkerLimitError: Decodable {
    let error: String
    let plan: String
    let limit: Int
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
