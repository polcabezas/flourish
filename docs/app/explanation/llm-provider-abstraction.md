# LLM Provider Abstraction

Why Flourish uses a protocol to abstract LLM providers, and how the design makes adding new providers safe and straightforward.

---

## The problem

Flourish supports multiple LLM providers (OpenRouter, Groq) and needs to be able to add more without touching the code that *uses* LLM responses. The calling code in `OverlayWindowController.runLLM()` should not care whether it's talking to OpenRouter or Groq — it just wants to send text and get back improved text, token counts, and model metadata.

Without abstraction, `runLLM()` would contain a `switch` statement that duplicates the full HTTP call logic for each provider. Adding a third provider would require modifying `runLLM()` directly.

---

## The protocol

```swift
protocol LLMService {
    func improvePrompt(
        _ text: String,
        systemPrompt: String,
        model: String
    ) async throws -> LLMResponse
}
```

This is the entire interface surface that `runLLM()` depends on. It has exactly one method. Both `OpenRouterService` and `GroqService` implement it.

The call site in `OverlayWindowController`:

```swift
let service: LLMService
switch Defaults.activeProviderEnum {
case .openRouter: service = OpenRouterService(apiKey: apiKey, model: selectedModel)
case .groq:       service = GroqService(apiKey: apiKey, model: selectedModel)
}
let response = try await service.improvePrompt(text, systemPrompt: systemPrompt, model: selectedModel)
```

Adding a third provider means adding one `case` to this switch — not modifying any of the LLM response handling, history saving, or paste logic below it.

---

## Services are not singletons

`OpenRouterService` and `GroqService` are instantiated **per-call** with the API key and model injected at construction time:

```swift
OpenRouterService(apiKey: apiKey, model: selectedModel)
```

This design:
- Avoids shared mutable state in services.
- Makes testing easy: pass a mock `LLMService` conformance.
- Ensures the service always uses the most current key and model at call time (no stale cached values).

Contrast with window controllers and stores, which are singletons because AppKit requires a single instance managing each window or database connection.

---

## Why not a class hierarchy

A base class with override hooks was considered. The protocol approach was chosen because:
- Both providers are already OpenAI-compatible. The shared logic (request/response shape) is a few lines, not a complex class hierarchy.
- Protocol witnesses are dispatched statically where possible, which is slightly more efficient than virtual dispatch.
- The interface is narrow — one method — making a shared base class overkill.

---

## LLMResponse as a value type

`LLMResponse` is a `struct`. It carries no identity — it's purely data. Using a struct:
- Prevents accidental aliasing bugs.
- Makes it trivially safe to pass across async boundaries.
- Makes testing straightforward (construct it directly in mock implementations).

---

## LLMError centralizes user-facing messages

Rather than returning different error types per provider, both services throw `LLMError`. This centralizes the mapping from HTTP status codes to user-facing messages in one enum. The overlay presents the `localizedDescription` of whatever `LLMError` is thrown — the presenting code never needs to know which provider threw it.

---

## Testing the abstraction

Any test can substitute a mock:

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

- [LLM Service API Reference](../reference/llm-service-api.md)
- [How-To: Add a New LLM Provider](../how-to/add-new-llm-provider.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [Data Models Reference](../reference/data-models.md) — `LLMResponse`, `LLMError`
