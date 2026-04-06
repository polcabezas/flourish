import Foundation

// MARK: - LLM Provider

enum LLMProvider: String, CaseIterable, Codable, Identifiable {
    case openRouter = "openrouter"
    case groq = "groq"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openRouter: return "OpenRouter"
        case .groq: return "Groq"
        }
    }

    var baseURL: URL {
        switch self {
        case .openRouter: return URL(string: "https://openrouter.ai/api/v1")!
        case .groq: return URL(string: "https://api.groq.com/openai/v1")!
        }
    }

    var defaultModel: String {
        switch self {
        case .openRouter: return "stepfun/step-3.5-flash:free"
        case .groq: return "llama-3.1-8b-instant"
        }
    }

    var keychainAccount: String { rawValue }
}
