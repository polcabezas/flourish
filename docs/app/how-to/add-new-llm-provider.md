# Add a New LLM Provider

How to extend Flourish with a third LLM provider (e.g., Anthropic direct, Ollama, Azure OpenAI).

---

## Overview

Flourish's LLM integration is abstracted behind the `LLMService` protocol. Adding a provider requires:
1. Implementing `LLMService` in a new service class.
2. Adding an enum case to `LLMProvider`.
3. Adding model options to `ModelOption`.
4. Adding settings keys to `AppSettings`.
5. Wiring the new provider into the UI (Settings, overlay pickers) and the orchestrator.

---

## Step 1 — Implement `LLMService`

Create a new file in `Flourish/Core/Services/`, e.g., `AnthropicService.swift`:

```swift
import Foundation

final class AnthropicService: LLMService {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse {
        // Build URLRequest for the provider's API
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [["role": "user", "content": text]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw LLMError.invalidResponse }
        switch http.statusCode {
        case 200: break
        case 401: throw LLMError.unauthorized
        case 429: throw LLMError.rateLimited
        default:  throw LLMError.serverError(http.statusCode)
        }

        // Parse response
        struct AnthropicResponse: Decodable {
            struct Content: Decodable { let text: String }
            struct Usage: Decodable { let input_tokens: Int; let output_tokens: Int }
            let content: [Content]
            let usage: Usage
            let model: String
        }
        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let content = decoded.content.first?.text, !content.isEmpty else { throw LLMError.noContent }
        return LLMResponse(
            text: content,
            tokensIn: decoded.usage.input_tokens,
            tokensOut: decoded.usage.output_tokens,
            model: decoded.model
        )
    }
}
```

---

## Step 2 — Add the provider enum case

In `Flourish/Core/Models/LLMProvider.swift`, add:

```swift
enum LLMProvider: String, CaseIterable, Codable, Defaults.Serializable {
    case openRouter = "openrouter"
    case groq = "groq"
    case anthropic = "anthropic"   // ← new

    var displayName: String {
        switch self {
        case .openRouter: return "OpenRouter"
        case .groq:       return "Groq"
        case .anthropic:  return "Anthropic"   // ← new
        }
    }
}
```

---

## Step 3 — Add model options

In `Flourish/Core/Models/ModelOption.swift`, add Anthropic model entries:

```swift
static let anthropicModels: [ModelOption] = [
    ModelOption(id: "claude-opus-4-6", name: "Claude Opus 4.6",
                pricePerMTokenIn: 15.00, pricePerMTokenOut: 75.00),
    ModelOption(id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6",
                pricePerMTokenIn: 3.00, pricePerMTokenOut: 15.00),
]
```

---

## Step 4 — Add settings keys

In `Flourish/Core/AppSettings.swift`, add keys for the new provider:

```swift
extension Defaults.Keys {
    static let anthropicEnabled = Key<Bool>("anthropicEnabled", default: false)
    static let anthropicModel   = Key<String>("anthropicModel", default: "claude-sonnet-4-6")
    static let anthropicCustomModels = Key<[String]>("anthropicCustomModels", default: [])
}
```

---

## Step 5 — Store the API key in Keychain

`KeychainService` uses `provider.rawValue` as the Keychain account. Since you added `anthropic` as a raw value, `KeychainService.shared.save(key, for: .anthropic)` works automatically.

---

## Step 6 — Wire into `OverlayWindowController.runLLM()`

In `OverlayWindowController.swift`, extend the provider switch statement:

```swift
let service: LLMService
switch Defaults.activeProviderEnum {
case .openRouter:
    service = OpenRouterService(apiKey: apiKey, model: selectedModel)
case .groq:
    service = GroqService(apiKey: apiKey, model: selectedModel)
case .anthropic:
    service = AnthropicService(apiKey: apiKey, model: selectedModel)
}
```

---

## Step 7 — Add UI in SettingsPanelView

Add a Providers section for Anthropic following the same pattern as OpenRouter and Groq in `SettingsPanelView.swift`: toggle, secure field, model picker, test button.

---

## Step 8 — Add to the overlay provider picker

In `ProviderPickerView.swift`, the picker iterates over `LLMProvider.allCases`. Since Anthropic is a new CaseIterable case, it appears automatically. Verify the display name and icon if applicable.

---

## Related

- [LLM Service API Reference](../reference/llm-service-api.md)
- [LLM Provider Abstraction Explanation](../explanation/llm-provider-abstraction.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [Data Models Reference](../reference/data-models.md)
