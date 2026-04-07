# LLM Provider Abstraction

Why flourish uses a protocol to abstract LLM access, and how the Cloudflare Worker proxy architecture fulfills the original goals of that protocol.

---

## The original problem

flourish needs to send prompt text to an LLM and receive improved text back. The calling code in `OverlayWindowController.runLLM()` should not care about which provider is used, how requests are authenticated, or what the wire format looks like — it just wants to send text and get back improved text with token metadata.

The `LLMService` protocol captures this contract:

```swift
protocol LLMService {
    func improvePrompt(
        _ text: String,
        systemPrompt: String,
        model: String
    ) async throws -> LLMResponse
}
```

This is the entire interface surface that `runLLM()` depends on.

---

## Current architecture: single proxy implementation

With the move to a Cloudflare Worker proxy (ADR-015), there is now one concrete implementation: `flourishProxyService`. The call site in `OverlayWindowController` is simple:

```swift
let service: LLMService = flourishProxyService()
let response = try await service.improvePrompt(text, systemPrompt: systemPrompt, model: "")
```

There is no `switch` statement over providers, no API key retrieval, and no model selection in the app. The Worker handles all of that.

The protocol is retained because:
- It makes testing straightforward: inject a mock `LLMService` conformance in tests to avoid real HTTP calls.
- If a second implementation is ever needed (e.g., a local model via MLX), the call site does not change.

---

## Where provider and model decisions now live

Provider and model are controlled at the Worker level, not in the app:

```
cloudflare/wrangler.toml
    ACTIVE_PROVIDER = "openrouter"
    ACTIVE_MODEL    = "google/gemini-2.0-flash-001"
```

Changing provider or model requires `wrangler deploy` only — no app rebuild. This is the key architectural benefit of moving selection to the Worker: iteration on model quality is decoupled from the app release cycle.

---

## Services are not singletons

`flourishProxyService` is instantiated **per-call**:

```swift
let service = flourishProxyService()
```

This design:
- Avoids shared mutable state.
- Makes testing easy: pass a mock `LLMService` conformance.
- Ensures the service always reads `Info.plist` values at call time (no stale cached config).

Contrast with window controllers and stores, which are singletons because AppKit requires a single instance managing each window or database connection.

---

## LLMResponse as a value type

`LLMResponse` is a `struct`. It carries no identity — it's purely data. Using a struct:
- Prevents accidental aliasing bugs.
- Makes it trivially safe to pass across async boundaries.
- Makes testing straightforward (construct it directly in mock implementations).

---

## LLMError centralizes user-facing messages

Both `flourishProxyService` and any future implementations throw `LLMError`. This centralizes the mapping from HTTP status codes to user-facing messages in one enum. The overlay presents the `localizedDescription` of whatever `LLMError` is thrown — the presenting code never needs to know the details of where the error came from.

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

Inject it into `OverlayWindowController` during tests to avoid real HTTP calls to the proxy.

---

## Related

- [LLM Service API Reference](../reference/llm-service-api.md)
- [How-To: Add Support for a New LLM Provider](../how-to/add-new-llm-provider.md)
- [How-To: Deploy or Update the Worker](../how-to/deploy-worker.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [Data Models Reference](../reference/data-models.md) — `LLMResponse`, `LLMError`
