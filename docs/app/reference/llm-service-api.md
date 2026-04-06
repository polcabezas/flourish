# LLM Service API Reference

The protocol, implementations, request/response shapes, error types, and external API specifications for Flourish's LLM integration.

---

## Protocol: `LLMService`

**File:** `Core/Services/LLMService.swift`

```swift
protocol LLMService {
    func improvePrompt(
        _ text: String,
        systemPrompt: String,
        model: String
    ) async throws -> LLMResponse
}
```

| Parameter | Description |
|-----------|-------------|
| `text` | The user's original prompt text |
| `systemPrompt` | The assembled system prompt (base template + profile guidelines) |
| `model` | The provider-specific model ID string |

Returns `LLMResponse` on success. Throws `LLMError` on any failure.

---

## `LLMResponse`

```swift
struct LLMResponse {
    let text: String       // Improved prompt returned by the model
    let tokensIn: Int      // Input (prompt) tokens consumed
    let tokensOut: Int     // Output (completion) tokens generated
    let model: String      // Actual model ID that responded
}
```

---

## `LLMError`

```swift
enum LLMError: LocalizedError {
    case missingAPIKey(String)   // Provider name as associated value
    case emptyInput
    case badRequest(String)      // API error message
    case unauthorized
    case billingError
    case rateLimited
    case serverError(Int)        // HTTP status code
    case invalidResponse
    case noContent
}
```

| Case | User-Facing Message | When Thrown |
|------|---------------------|-------------|
| `missingAPIKey(provider)` | "No API key for {provider}. Add it in Settings → Providers." | API key not found in Keychain |
| `emptyInput` | "Prompt is empty." | Input text is blank or whitespace-only |
| `badRequest(msg)` | The API error message | HTTP 400 |
| `unauthorized` | "Invalid API key. Check your key in Settings → Providers." | HTTP 401 |
| `billingError` | "Billing issue. Check your account balance at openrouter.ai/credits." | HTTP 402 |
| `rateLimited` | "Rate limit reached. Wait a moment and try again." | HTTP 429 |
| `serverError(code)` | "Server error ({code}). The provider may be temporarily unavailable." | HTTP 5xx or unexpected code |
| `invalidResponse` | "Unexpected response format from the API." | JSON decode failure or non-HTTP response |
| `noContent` | "The model returned an empty response." | Choices array empty or content string empty |

---

## `BasePrompt`

**File:** `Core/Services/BasePrompt.swift`

Assembles the system prompt sent to the LLM.

```swift
enum BasePrompt {
    static func build(profile: GuidelineProfile?) -> String
}
```

The base template contains a `{guidelines}` placeholder. `build(profile:)`:
1. Reads `Defaults[.basePromptTemplate]` — uses it if non-empty.
2. Falls back to the built-in default template (hardcoded in `BasePrompt.swift`).
3. Substitutes `{guidelines}` with `profile.systemPrompt` if a profile is provided.
4. Substitutes `{guidelines}` with an empty string (or a neutral instruction) if no profile is selected.

---

## OpenRouterService

**File:** `Core/Services/OpenRouterService.swift`

### Base URL
```
https://openrouter.ai/api/v1
```

### Endpoint
```
POST /chat/completions
```

### Request Headers

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer {apiKey}` |
| `Content-Type` | `application/json` |
| `HTTP-Referer` | `com.personal.flourish` |
| `X-Title` | `Flourish` |

Timeout: **60 seconds**

### Request Body

```json
{
  "model": "google/gemini-2.0-flash-001",
  "stream": false,
  "messages": [
    { "role": "system", "content": "<assembled system prompt>" },
    { "role": "user",   "content": "<original prompt text>" }
  ]
}
```

### Response Body (success — HTTP 200)

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "<improved prompt>"
      }
    }
  ],
  "usage": {
    "prompt_tokens": 142,
    "completion_tokens": 87
  },
  "model": "google/gemini-2.0-flash-001"
}
```

### Swift decode types

```swift
struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
    let usage: Usage?
    let model: String?

    struct Choice: Decodable {
        let message: Message
        struct Message: Decodable {
            let content: String?
        }
    }

    struct Usage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
    }
}
```

### HTTP Status → LLMError mapping

| HTTP Status | LLMError |
|-------------|----------|
| 200 | *(success)* |
| 400 | `.badRequest(msg)` |
| 401 | `.unauthorized` |
| 402 | `.billingError` |
| 429 | `.rateLimited` |
| Any other | `.serverError(statusCode)` |

---

## GroqService

**File:** `Core/Services/GroqService.swift`

### Base URL
```
https://api.groq.com/openai/v1
```

### Endpoint
```
POST /chat/completions
```

The Groq API is **OpenAI-compatible**. The request and response bodies, headers, and error handling are identical to OpenRouterService.

The only differences:
- Different base URL
- No `HTTP-Referer` or `X-Title` headers (not required by Groq)
- Different set of available model IDs

### HTTP Status → LLMError mapping

Same as OpenRouter.

---

## System Prompt Assembly

```
Final system prompt = base template with {guidelines} replaced
```

Example (with "More Concise" profile selected):

```
You are an expert prompt engineer. Your task is to improve the user's prompt
while preserving their intent. Apply the following guidelines:

Be concise. Remove all redundant words and phrases. Keep only what is
essential to communicate the intent clearly.

Return only the improved prompt. Do not explain your changes.
```

---

## Related

- [LLM Provider Abstraction Explanation](../explanation/llm-provider-abstraction.md)
- [Data Models Reference](data-models.md) — `LLMResponse`, `LLMProvider`, `ModelOption`
- [Prompt Improvement Workflow Explanation](../explanation/prompt-improvement-workflow.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [Supported Models Reference](supported-models.md)
