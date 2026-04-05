import Foundation

// MARK: - Model Option

struct ModelOption: Identifiable, Hashable {
    let id: String          // model identifier used in API calls
    let displayName: String
    let priceInputPerMToken: Double   // USD per 1M input tokens
    let priceOutputPerMToken: Double  // USD per 1M output tokens
    let provider: LLMProvider

    var isFree: Bool { priceInputPerMToken == 0 && priceOutputPerMToken == 0 }
}

// MARK: - Static Model Lists

extension ModelOption {

    // MARK: OpenRouter Models (curated, sorted by quality/price tradeoff)
    static let openRouterModels: [ModelOption] = [
        ModelOption(id: "google/gemini-2.0-flash-001",
                    displayName: "Gemini 2.0 Flash",
                    priceInputPerMToken: 0.10, priceOutputPerMToken: 0.40,
                    provider: .openRouter),
        ModelOption(id: "openai/gpt-4o-mini",
                    displayName: "GPT-4o Mini",
                    priceInputPerMToken: 0.15, priceOutputPerMToken: 0.60,
                    provider: .openRouter),
        ModelOption(id: "google/gemini-flash-1.5",
                    displayName: "Gemini 1.5 Flash",
                    priceInputPerMToken: 0.075, priceOutputPerMToken: 0.30,
                    provider: .openRouter),
        ModelOption(id: "anthropic/claude-3-haiku",
                    displayName: "Claude 3 Haiku",
                    priceInputPerMToken: 0.25, priceOutputPerMToken: 1.25,
                    provider: .openRouter),
        ModelOption(id: "meta-llama/llama-3.1-8b-instruct",
                    displayName: "Llama 3.1 8B",
                    priceInputPerMToken: 0.06, priceOutputPerMToken: 0.06,
                    provider: .openRouter),
        ModelOption(id: "meta-llama/llama-3.1-70b-instruct",
                    displayName: "Llama 3.1 70B",
                    priceInputPerMToken: 0.40, priceOutputPerMToken: 0.40,
                    provider: .openRouter),
        ModelOption(id: "mistralai/mistral-7b-instruct",
                    displayName: "Mistral 7B",
                    priceInputPerMToken: 0.07, priceOutputPerMToken: 0.07,
                    provider: .openRouter),
        ModelOption(id: "openai/gpt-4o",
                    displayName: "GPT-4o",
                    priceInputPerMToken: 2.50, priceOutputPerMToken: 10.00,
                    provider: .openRouter),
        ModelOption(id: "anthropic/claude-3.5-sonnet",
                    displayName: "Claude 3.5 Sonnet",
                    priceInputPerMToken: 3.00, priceOutputPerMToken: 15.00,
                    provider: .openRouter),
        ModelOption(id: "qwen/qwen-2.5-72b-instruct",
                    displayName: "Qwen 2.5 72B",
                    priceInputPerMToken: 0.35, priceOutputPerMToken: 0.40,
                    provider: .openRouter),
    ]

    // MARK: Groq Models (free tier, LPU-accelerated)
    static let groqModels: [ModelOption] = [
        ModelOption(id: "llama-3.1-70b-versatile",
                    displayName: "Llama 3.1 70B Versatile",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
        ModelOption(id: "llama-3.3-70b-versatile",
                    displayName: "Llama 3.3 70B Versatile",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
        ModelOption(id: "llama-3.1-8b-instant",
                    displayName: "Llama 3.1 8B Instant",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
        ModelOption(id: "llama3-70b-8192",
                    displayName: "Llama 3 70B",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
        ModelOption(id: "mixtral-8x7b-32768",
                    displayName: "Mixtral 8x7B",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
        ModelOption(id: "gemma2-9b-it",
                    displayName: "Gemma 2 9B",
                    priceInputPerMToken: 0, priceOutputPerMToken: 0,
                    provider: .groq),
    ]

    static func models(for provider: LLMProvider) -> [ModelOption] {
        switch provider {
        case .openRouter: return openRouterModels
        case .groq: return groqModels
        }
    }

    static func find(id: String, in provider: LLMProvider) -> ModelOption? {
        models(for: provider).first(where: { $0.id == id })
    }

    // MARK: - Cost Estimation

    static func estimateCost(modelId: String, provider: LLMProvider, tokensIn: Int, tokensOut: Int) -> Double {
        guard let model = find(id: modelId, in: provider) else { return 0 }
        let inputCost  = Double(tokensIn)  / 1_000_000 * model.priceInputPerMToken
        let outputCost = Double(tokensOut) / 1_000_000 * model.priceOutputPerMToken
        return inputCost + outputCost
    }
}
