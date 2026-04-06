# ADR-006: Protocol-Based LLM Service Abstraction

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Define `LLMService` as a Swift protocol with a single method. All LLM provider integrations conform to this protocol. Calling code in `OverlayWindowController` depends only on the protocol, not concrete types.

---

## Context

Flourish supports two LLM providers (OpenRouter, Groq) and anticipates adding more. Without abstraction, the `runLLM()` function would contain duplicated request-building code for each provider and would need to be modified every time a provider is added or removed.

The two providers happen to share an OpenAI-compatible API shape, but this is not guaranteed for future providers. The abstraction must not assume API compatibility — it must only define the observable behavior.

---

## Alternatives Considered

### Single service class with a `switch` statement
One `LLMService` class that contains provider-specific logic in a `switch Defaults.activeProviderEnum`. Simple for two providers, but grows linearly with each new provider. Adding a provider requires modifying a shared, growing class. Rejected.

### Class inheritance (base class + subclasses)
A base `LLMService` class with `OpenRouterService` and `GroqService` subclasses. Works, but Swift protocols achieve the same polymorphism without the limitations of single-inheritance. Rejected.

### Function parameter (provider enum → async function)
Pass a function or closure as the LLM implementation. Less idiomatic Swift than a protocol; harder to test with mock conformances. Rejected.

---

## Decision Rationale

The `LLMService` protocol:
- Has exactly one method: `improvePrompt(_:systemPrompt:model:) async throws -> LLMResponse`.
- Minimizes the surface area that any new provider must implement.
- Services are instantiated per-call (no shared mutable state).
- The protocol makes mock implementations trivial for testing.
- Adding a new provider = new file implementing `LLMService`, one new `case` in `OverlayWindowController.runLLM()`'s switch.

---

## Consequences

- `OverlayWindowController.runLLM()` is provider-agnostic. ✓
- New providers can be added without modifying existing service files. ✓
- `LLMError` is shared across all providers — consistent user-facing messages regardless of which provider threw the error. ✓
- Services are stateless (instantiated per-call) — no risk of stale API keys or model IDs from a cached singleton. ✓
- The protocol requires async/throws, which means all implementations must handle networking and error propagation correctly — no shortcuts. ✓

---

## Related

- [LLM Service API Reference](../reference/llm-service-api.md)
- [LLM Provider Abstraction Explanation](../explanation/llm-provider-abstraction.md)
- [How-To: Add a New LLM Provider](../how-to/add-new-llm-provider.md)
