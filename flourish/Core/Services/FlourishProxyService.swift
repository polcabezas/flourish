import Foundation

// MARK: - flourish Proxy Service
// Routes all LLM requests through the Cloudflare Worker.
// Auth: per-user Supabase JWT fetched from AuthService (replaces static proxy token).
// The Worker validates the JWT, checks plan limits, and holds real LLM API keys.

final class flourishProxyService: LLMService {
    private let proxyURL: URL

    init() {
        let info = Bundle.main.infoDictionary
        guard
            let urlString = info?["flourishProxyURL"] as? String, !urlString.isEmpty,
            let url = URL(string: "https://" + urlString + "/improve")
        else {
            fatalError("flourish: Missing proxy config. Set flourish_PROXY_URL in flourish/Config/Secrets.xcconfig.")
        }
        self.proxyURL = url
    }

    func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyInput
        }

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": text],
            ]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        guard let token = await AuthService.shared.currentAccessToken() else {
            throw LLMError.unauthorized
        }

        let (data, httpResponse) = try await perform(bodyData: bodyData, token: token)

        // On 401, the session may be expired — supabase-swift auto-refreshes on next access
        if httpResponse.statusCode == 401 {
            guard let refreshedToken = await AuthService.shared.currentAccessToken() else {
                throw LLMError.unauthorized
            }
            let (retryData, retryResponse) = try await perform(bodyData: bodyData, token: refreshedToken)
            return try parse(data: retryData, httpResponse: retryResponse)
        }

        return try parse(data: data, httpResponse: httpResponse)
    }

    // MARK: - Private

    private func perform(bodyData: Data, token: String) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response as! HTTPURLResponse)
    }

    private func parse(data: Data, httpResponse: HTTPURLResponse) throws -> LLMResponse {
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw LLMError.unauthorized
        case 402:
            throw LLMError.billingError
        case 429:
            if let limitError = try? JSONDecoder().decode(WorkerLimitError.self, from: data),
               limitError.error == "monthly_limit_reached" {
                throw LLMError.monthlyLimitReached(plan: limitError.plan, limit: limitError.limit)
            }
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

        let providerHeader = httpResponse.value(forHTTPHeaderField: "X-flourish-Provider") ?? ""
        let provider = LLMProvider(rawValue: providerHeader) ?? .openRouter

        return LLMResponse(
            improvedText: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tokensIn:  decoded.usage?.promptTokens     ?? 0,
            tokensOut: decoded.usage?.completionTokens ?? 0,
            modelId:   decoded.model ?? "unknown",
            provider:  provider
        )
    }
}
