import Foundation

// MARK: - Flourish Proxy Service
// Routes all LLM requests through the company's Cloudflare Worker.
// The worker holds the real provider API key and controls model/provider selection.
// The app embeds only a proxy bearer token (FLOURISH_PROXY_TOKEN via Secrets.xcconfig).

final class FlourishProxyService: LLMService {
    private let proxyURL: URL
    private let proxyToken: String

    init() {
        let info = Bundle.main.infoDictionary
        guard
            let urlString = info?["FlourishProxyURL"] as? String, !urlString.isEmpty,
            let url = URL(string: "https://" + urlString + "/improve"),
            let token = info?["FlourishProxyToken"] as? String, !token.isEmpty
        else {
            fatalError("Flourish: Missing proxy config. Fill in FLOURISH_PROXY_URL and FLOURISH_PROXY_TOKEN in Flourish/Config/Secrets.xcconfig.")
        }
        self.proxyURL = url
        self.proxyToken = token
    }

    func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyInput
        }

        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(proxyToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
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

        // Worker sets X-Flourish-Provider so history tracks the correct provider
        let providerHeader = httpResponse.value(forHTTPHeaderField: "X-Flourish-Provider") ?? ""
        let provider = LLMProvider(rawValue: providerHeader) ?? .openRouter

        return LLMResponse(
            improvedText: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tokensIn:  decoded.usage?.promptTokens     ?? 0,
            tokensOut: decoded.usage?.completionTokens ?? 0,
            modelId:  decoded.model ?? "unknown",
            provider: provider
        )
    }
}
