# Data Models Reference

All Swift model types in `Flourish/Core/Models/`.

---

## GuidelineProfile

**File:** `Core/Models/GuidelineProfile.swift`

A named set of system prompt instructions for a specific writing style or intent.

```swift
struct GuidelineProfile: Identifiable, Codable, Defaults.Serializable, Equatable {
    let id: UUID
    var name: String
    var systemPrompt: String
    var isBuiltIn: Bool
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Stable identifier; used as `lastSelectedProfileId` key |
| `name` | `String` | Display name shown in overlay profile picker |
| `systemPrompt` | `String` | Full instructions injected at `{guidelines}` in the base prompt |
| `isBuiltIn` | `Bool` | `true` for the 6 built-in profiles; prevents editing/deletion |

### Built-in profiles (static instances)

| Name | Intent |
|------|--------|
| Clearer | Remove ambiguity; improve readability |
| More Concise | Trim to essential information |
| More Detailed | Expand with specifics and context |
| Professional | Formal, polished language |
| Developer | Precise, technical phrasing |
| Creative | Imaginative and engaging tone |

### Serialization

Conforms to `Defaults.Serializable` via `Codable`. The full array is JSON-encoded and stored in `UserDefaults` under the `profiles` key.

---

## HistoryEntry

**File:** `Core/Models/HistoryEntry.swift`

A single prompt-improvement event stored in SQLite.

```swift
struct HistoryEntry: Identifiable {
    var id: Int64?
    let createdAt: Date
    let originalPrompt: String
    let improvedPrompt: String
    let provider: String          // LLMProvider.rawValue
    let modelId: String
    var tokensIn: Int
    var tokensOut: Int
    var estimatedCostUSD: Double
}
```

| Field | Type | SQLite Column | Description |
|-------|------|---------------|-------------|
| `id` | `Int64?` | `id` (AUTOINCREMENT) | Assigned by GRDB on insert |
| `createdAt` | `Date` | `created_at` (indexed) | UTC timestamp of the improvement |
| `originalPrompt` | `String` | `original_prompt` | User's original text |
| `improvedPrompt` | `String` | `improved_prompt` | LLM's output |
| `provider` | `String` | `provider` | Raw value: `"openrouter"` or `"groq"` |
| `modelId` | `String` | `model_id` | Exact model identifier used |
| `tokensIn` | `Int` | `tokens_in` | Prompt token count |
| `tokensOut` | `Int` | `tokens_out` | Completion token count |
| `estimatedCostUSD` | `Double` | `estimated_cost_usd` | Client-side cost estimate |

### GRDB conformances

- `FetchableRecord`: decodes from SQLite rows using `init(row:)`
- `MutablePersistableRecord`: encodes to database; `id` is mutated on insert

### Cost calculation

```swift
let cost = (Double(tokensIn) / 1_000_000.0) * model.pricePerMTokenIn
         + (Double(tokensOut) / 1_000_000.0) * model.pricePerMTokenOut
```

Groq models have `pricePerMTokenIn = 0` and `pricePerMTokenOut = 0` (free tier).

---

## LLMProvider

**File:** `Core/Models/LLMProvider.swift`

Enum representing supported LLM providers.

```swift
enum LLMProvider: String, CaseIterable, Codable, Defaults.Serializable {
    case openRouter = "openrouter"
    case groq       = "groq"
}
```

| Case | Raw Value | Display Name |
|------|-----------|--------------|
| `.openRouter` | `"openrouter"` | OpenRouter |
| `.groq` | `"groq"` | Groq |

The raw value is used as:
- The `Defaults[.activeProvider]` persisted string
- The Keychain account identifier for the API key

---

## ModelOption

**File:** `Core/Models/ModelOption.swift`

Metadata for a single LLM model, used to populate the model picker and calculate costs.

```swift
struct ModelOption: Identifiable, Equatable {
    let id: String                  // API model identifier
    let name: String                // Human-readable display name
    let pricePerMTokenIn: Double    // USD per million input tokens
    let pricePerMTokenOut: Double   // USD per million output tokens
}
```

### OpenRouter models (built-in)

| id | name | $/M in | $/M out |
|----|------|--------|---------|
| `google/gemini-2.0-flash-001` | Gemini 2.0 Flash | $0.10 | $0.40 |
| `openai/gpt-4o-mini` | GPT-4o Mini | $0.15 | $0.60 |
| `google/gemini-flash-1.5` | Gemini 1.5 Flash | $0.075 | $0.30 |
| `anthropic/claude-3-haiku` | Claude 3 Haiku | $0.25 | $1.25 |
| `meta-llama/llama-3.1-8b-instruct` | Llama 3.1 8B | $0.06 | $0.06 |
| `meta-llama/llama-3.1-70b-instruct` | Llama 3.1 70B | $0.40 | $0.40 |
| `mistralai/mistral-7b-instruct` | Mistral 7B | $0.07 | $0.07 |
| `openai/gpt-4o` | GPT-4o | $2.50 | $10.00 |
| `anthropic/claude-3.5-sonnet` | Claude 3.5 Sonnet | $3.00 | $15.00 |
| `qwen/qwen-2.5-72b-instruct` | Qwen 2.5 72B | $0.35 | $0.40 |

### Groq models (built-in, all free)

| id | name |
|----|------|
| `llama-3.1-70b-versatile` | Llama 3.1 70B Versatile |
| `llama-3.3-70b-versatile` | Llama 3.3 70B Versatile |
| `llama-3.1-8b-instant` | Llama 3.1 8B Instant |
| `llama3-70b-8192` | Llama 3 70B |
| `mixtral-8x7b-32768` | Mixtral 8x7B |
| `gemma2-9b-it` | Gemma 2 9B |

---

## LLMResponse

**File:** `Core/Services/LLMService.swift`

The structured result returned by all `LLMService` implementations.

```swift
struct LLMResponse {
    let text: String        // The improved prompt text
    let tokensIn: Int       // Prompt tokens consumed
    let tokensOut: Int      // Completion tokens generated
    let model: String       // Exact model ID that responded (may differ from requested)
}
```

---

## Related

- [LLM Service API Reference](llm-service-api.md)
- [Database Schema Reference](database-schema.md)
- [App Settings Reference](app-settings.md)
- [Supported Models Reference](supported-models.md)
