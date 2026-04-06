# LLM Service API Reference

The protocol, implementation, request/response shapes, and error types for Flourish's LLM integration.

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
| `model` | Reserved; passed through to the Worker but the Worker uses `ACTIVE_MODEL` from its environment |

Returns `LLMResponse` on success. Throws `LLMError` on any failure.

---

## `LLMResponse`

```swift
struct LLMResponse {
    let text: String       // Improved prompt returned by the model
    let tokensIn: Int      // Input (prompt) tokens consumed
    let tokensOut: Int     // Output (completion) tokens generated
    let model: String      // Actual model ID that responded (from provider)
}
```

---

## `LLMError`

```swift
enum LLMError: LocalizedError {
    case missingConfiguration    // Proxy URL or token not set in Info.plist
    case emptyInput
    case unauthorized            // Worker rejected the proxy token (HTTP 401)
    case badRequest(String)      // API error message forwarded from provider
    case billingError
    case rateLimited
    case serverError(Int)        // HTTP status code
    case invalidResponse
    case noContent
}
```

| Case | User-Facing Message | When Thrown |
|------|---------------------|-------------|
| `missingConfiguration` | "Proxy not configured. Contact support." | `FlourishProxyURL` or `FlourishProxyToken` missing from `Info.plist` |
| `emptyInput` | "Prompt is empty." | Input text is blank or whitespace-only |
| `unauthorized` | "Proxy authentication failed. Rebuild the app with a valid token." | Worker returned HTTP 401 |
| `badRequest(msg)` | The API error message forwarded from provider | HTTP 400 from provider |
| `billingError` | "Billing issue. Contact the Flourish team." | HTTP 402 from provider |
| `rateLimited` | "Rate limit reached. Wait a moment and try again." | HTTP 429 |
| `serverError(code)` | "Server error ({code}). The service may be temporarily unavailable." | HTTP 5xx or unexpected status |
| `invalidResponse` | "Unexpected response format from the proxy." | JSON decode failure or non-HTTP response |
| `noContent` | "The model returned an empty response." | Response body has no content |

---

## `FlourishProxyService`

**File:** `Core/Services/FlourishProxyService.swift`

The sole concrete implementation of `LLMService`. Reads proxy configuration from `Bundle.main.infoDictionary` at call time.

### Configuration keys (from `Info.plist`)

| Key | Source | Description |
|-----|--------|-------------|
| `FlourishProxyURL` | `FLOURISH_PROXY_URL` in `Secrets.xcconfig` | Hostname only (e.g., `flourish-proxy.yoursubdomain.workers.dev`). `https://` is prepended in code |
| `FlourishProxyToken` | `FLOURISH_PROXY_TOKEN` in `Secrets.xcconfig` | Bearer token used in the `Authorization` header |

### Endpoint

```
POST https://<FlourishProxyURL>/improve
```

### Request Headers

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer <FlourishProxyToken>` |
| `Content-Type` | `application/json` |

Timeout: **60 seconds**

### Request Body

```json
{
  "text": "<original prompt text>",
  "systemPrompt": "<assembled system prompt>"
}
```

### Response Body (success — HTTP 200)

```json
{
  "text": "<improved prompt>",
  "tokensIn": 142,
  "tokensOut": 87,
  "model": "google/gemini-2.0-flash-001"
}
```

### Swift decode type

```swift
struct ProxyResponse: Decodable {
    let text: String
    let tokensIn: Int
    let tokensOut: Int
    let model: String
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

## Testing the Abstraction

Any test can substitute a mock conformance:

```swift
struct MockLLMService: LLMService {
    var response: LLMResponse
    func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse {
        response
    }
}
```

Inject it into `OverlayWindowController` during tests to avoid real HTTP calls.

---

## Related

- [LLM Provider Abstraction Explanation](../explanation/llm-provider-abstraction.md)
- [Data Models Reference](data-models.md) — `LLMResponse`, `GuidelineProfile`
- [Prompt Improvement Workflow Explanation](../explanation/prompt-improvement-workflow.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [Build Configuration Reference](build-configuration.md) — Secrets.xcconfig setup
