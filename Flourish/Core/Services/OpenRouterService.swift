import Foundation

// MARK: - OpenRouter Service

final class OpenRouterService: LLMService {
    private let apiKey: String
    private let baseURL = URL(string: "https://openrouter.ai/api/v1")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyInput
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue("com.personal.flourish", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Flourish",            forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": text],
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw LLMError.unauthorized
        case 402:
            throw LLMError.billingError
        case 429:
            throw LLMError.rateLimited
        default:
            // Try to extract error message
            if let errResp = try? JSONDecoder().decode(ChatCompletionError.self, from: data),
               let msg = errResp.error?.message {
                throw LLMError.badRequest(msg)
            }
            throw LLMError.serverError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw LLMError.noContent
        }

        return LLMResponse(
            improvedText: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tokensIn:  decoded.usage?.promptTokens     ?? 0,
            tokensOut: decoded.usage?.completionTokens ?? 0,
            modelId: model,
            provider: .openRouter
        )
    }
}
