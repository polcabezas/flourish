# Data Models Reference

All Swift model types in `Flourish/Core/Models/`.

---

## GuidelineProfile

**File:** `Core/Models/GuidelineProfile.swift`

A named set of system prompt instructions for a specific writing style or intent.

```swift
struct GuidelineProfile: Identifiable, Codable, Hashable, Defaults.Serializable {
    var id: UUID
    var name: String
    var systemPrompt: String
    var isBuiltin: Bool
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Stable identifier; used as `lastSelectedProfileId` key |
| `name` | `String` | Display name shown in overlay profile picker |
| `systemPrompt` | `String` | Full instructions injected at `{guidelines}` in the base prompt |
| `isBuiltin` | `Bool` | `true` for the 6 built-in profiles; renders them read-only in the UI (Edit and Delete actions hidden) |

### Built-in profiles (static instances)

Designed for non-technical office workers. Each profile's `systemPrompt` is outcome-oriented — it tells the improving LLM what kind of professional output to produce, not how to structure the prompt itself.

| Name | Intended output |
|------|----------------|
| Professional Email | Complete, send-ready email with appropriate tone, recipient context, and clear objective |
| Summarize | TL;DR + 3–5 key bullet points + any decisions highlighted, ≤20% of source length |
| Explain Simply | Jargon-free explanation with analogy, general-to-specific structure, length appropriate to topic complexity |
| Draft a Document | Structured professional document with structure appropriate to document type, audience, and tone |
| Analyze & Advise | Direct recommendation + supporting reasoning + risks + concrete next steps |
| Brainstorm | 5–8 distinct ideas with one-sentence rationale and fastest-to-implement vs. highest-impact note |

Each built-in profile closes with an explicit preservation statement of the form: "Include only context present in the original — do not invent [role-specific details] if not stated." This makes the non-invention contract specific to each profile's domain rather than relying on a generic base-prompt rule.

### Read-only in the UI

When `isBuiltin == true`, both `ProfilesView` (main window sidebar) and `ProfilesTab` (Settings) hide the Edit and Delete actions for that profile. A "Built-in" badge is shown instead of an edit affordance. The profile can be selected and used normally; it cannot be modified or removed by the user.

User-created profiles (`isBuiltin == false`) have full CRUD available.

### Seeding

Built-in profiles are re-seeded from `GuidelineProfile.builtins` on every app launch in `AppDelegate.applicationDidFinishLaunching`. This ensures code changes to built-in profiles take effect without requiring a UserDefaults reset. User-created profiles (`isBuiltin == false`) are preserved.

```swift
let userProfiles = Defaults[.profiles].filter { !$0.isBuiltin }
Defaults[.profiles] = GuidelineProfile.builtins + userProfiles
```

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
    let provider: String          // Provider identifier (from model ID prefix or proxy response)
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
| `provider` | `String` | `provider` | Provider identifier derived from the model ID returned by the proxy (e.g., `"google"`, `"openai"`, `"groq"`) |
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

Groq models have `pricePerMTokenIn = 0` and `pricePerMTokenOut = 0` (free tier). If the model ID returned by the proxy does not match any `ModelOption` entry, cost defaults to `$0.00`.

---

## ModelOption

**File:** `Core/Models/ModelOption.swift`

Metadata for a single LLM model, used to calculate per-request cost estimates from token counts. The model list is no longer surfaced in the UI — it is used only for cost calculation when the model ID in `LLMResponse.model` matches a known entry.

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

## TargetPlatform

**File:** `Core/Models/TargetPlatform.swift`

An enum identifying the AI assistant the user intends to paste the improved prompt into. Each case carries a platform-specific formatting instruction string that `BasePrompt.build` appends to the system prompt.

```swift
enum TargetPlatform: String, CaseIterable, Codable, Defaults.Serializable, Identifiable {
    case generic    = "generic"
    case claude     = "claude"
    case chatgpt    = "chatgpt"
    case gemini     = "gemini"
    case perplexity = "perplexity"
}
```

| Case | Display Name | Formatting instruction summary |
|------|-------------|-------------------------------|
| `.generic` | Universal | `nil` — no appendix added to the prompt |
| `.claude` | Claude | Descriptive XML tags (`<task>`, `<context>`, `<constraints>`, `<output_format>`); reference material at top; rationale stated alongside each constraint |
| `.chatgpt` | ChatGPT | Markdown (`###` headers, `---` separators, bullet/numbered lists); key constraint repeated at the end to counteract recency bias |
| `.gemini` | Gemini | `<context>` XML wrapper at start; structurally identical few-shot examples; task then query pattern |
| `.perplexity` | Perplexity | Keyword-rich search query style; brief system message section only; temporal framing when recency matters |

### Behaviour

`TargetPlatform.formattingInstruction` returns an `Optional<String>` — `nil` for `.generic`, a multi-line instruction string for all other cases. `BasePrompt.build(guidelines:targetPlatform:)` appends the instruction verbatim after a blank line when non-`nil`.

### Persistence

Stored in `UserDefaults` via the Defaults package under the `"targetPlatform"` key. Automatically persists the user's last selection across sessions.

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
