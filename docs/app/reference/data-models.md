# Data Models Reference

All Swift model types in `flourish/Core/Models/`.

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

## AuthUser

**File:** `Core/Services/AuthService.swift`

A lightweight representation of the signed-in user, derived from the Supabase `Session`. Not a persisted model — reconstructed from the live `authStateChanges` session on every auth state transition.

```swift
struct AuthUser {
    let id: String      // Supabase user UUID (used as user_id in user_subscriptions)
    let email: String   // User's email address
}
```

`AuthService.shared.currentUser` exposes the current `AuthUser?`. `nil` when no session exists.

---

## UsageInfo

**File:** `Main/AccountViewModel.swift`

The app-layer model populated from the `GET /account/usage` Worker response. (The private `UsageResponse: Decodable` struct in `AccountViewModel` handles decoding; `UsageInfo` is a clean domain type.)

```swift
struct UsageInfo {
    let plan: String        // "free" or "pro"
    let requestsThisMonth: Int  // Counter since last reset
    let limit: Int?             // 30 for free, nil for pro (unlimited)
    let resetAt: String         // ISO-8601 date string: start of current billing period
}
```

| Field | Description |
|-------|-------------|
| `plan` | Plan tier as a raw string from Supabase. `AccountView` renders a `PlanBadge` from this value |
| `requestsThisMonth` | Requests made since `resetAt`. Incremented atomically by the Worker via `rpc/increment_user_requests` on each successful `/improve` call |
| `limit` | Monthly request cap: `30` for free, `nil` for pro (unlimited). `AccountView` shows a progress bar when non-nil and "Unlimited requests" when nil |
| `resetAt` | ISO-8601 date string (`YYYY-MM-DD`) of the **start** of the current billing period (e.g. `"2026-04-01"`). `AccountViewModel` adds one calendar month before displaying to the user ("resets May 1") |

---

## LimitReachedViewModel

**File:** `Overlay/Views/LimitReachedView.swift`

Drives the auto-dismiss countdown in `LimitReachedPopupView`. Singleton, `@MainActor`.

```swift
@MainActor
final class LimitReachedViewModel: ObservableObject {
    static let shared = LimitReachedViewModel()
    static let totalTime: Double = 12.0

    @Published var timeRemaining: Double = LimitReachedViewModel.totalTime

    func reset() { timeRemaining = Self.totalTime }
}
```

`LimitReachedWindowController.shared.show()` calls `reset()` before presenting the popup. `LimitReachedPopupView` subscribes to a 0.05-second `Timer.publish` and decrements `timeRemaining` on each tick, driving a draining circular progress ring and auto-dismissing at zero.

---

## AccountViewModel

**File:** `Main/AccountViewModel.swift`

Coordinates all account-related async work for `AccountView`. `@MainActor ObservableObject`.

```swift
@MainActor
final class AccountViewModel: ObservableObject {
    @Published var usage: UsageInfo? = nil
    @Published var isLoadingUsage = false
    @Published var billingError: String? = nil
}
```

| Property | Description |
|----------|-------------|
| `usage` | Latest `UsageInfo` fetched from `GET /account/usage`; `nil` until first load |
| `isLoadingUsage` | True while the usage network call is in flight |
| `billingError` | Last checkout/portal error string, shown inline in `BillingSection` |

Refreshes usage automatically on two events:
- `flourishDidImprovePrompt` notification (posted after each successful improvement)
- `NSApplication.didBecomeActiveNotification` (catches plan changes made outside the app, e.g. via Stripe portal)

---

## WorkerLimitError

**File:** `Core/Services/flourishProxyService.swift` (part of `LLMError`)

Represents the 429 response returned by the Worker when a free-plan user exceeds their monthly request limit.

```swift
// HTTP 429 response body from Worker:
// { "error": "monthly_limit_reached", "plan": "free", "limit": 30 }

// Mapped to:
enum LLMError: LocalizedError {
    // ... existing cases ...
    case monthlyLimitReached
}
```

`flourishProxyService` inspects the HTTP status code and JSON body. When `status == 429` and `error == "monthly_limit_reached"`, it throws `LLMError.monthlyLimitReached`. `OverlayWindowController.showError()` handles this case by calling `LimitReachedWindowController.shared.show()` — a bottom-center floating popup with an Upgrade CTA and a 12-second auto-dismiss. Pro users never receive this error (`PLAN_LIMITS.pro = null`). See ADR-033 and ADR-034.

---

## LoaderState

**File:** `Loader/LoaderView.swift`

Observable state object shared between `LoaderView` and `LoaderWindowController`. `@MainActor ObservableObject`.

```swift
@MainActor
final class LoaderState: ObservableObject {
    enum Phase { case loading, success }
    @Published var phase: Phase = .loading
    @Published var successMessage: String = "Copied to clipboard"
    @Published var width: CGFloat = FS.loaderWidth
}
```

| Property | Type | Description |
|----------|------|-------------|
| `phase` | `Phase` | `.loading` shows a `ProgressView()` spinner tinted `flourishAccent`; `.success` shows a checkmark + `successMessage` |
| `successMessage` | `String` | `"Pasted"` when Cmd+V was fired into a confirmed focused text input; `"Copied to clipboard"` otherwise |
| `width` | `CGFloat` | Current pill width in points. Always kept in sync with the panel's `NSWindow` frame so `NSHostingView` reports a stable preferred content size and never triggers the `updateAnimatedWindowSize` loop. Defaults to `FS.loaderWidth` (80 pt) during loading; `LoaderWindowController` computes the success message width at runtime and sets this before transitioning to `.success` |

`LoaderWindowController.showSuccess(pasted:)` sets all three properties together before calling `applyFrame(width:)`, ensuring SwiftUI renders the success view inside the correct frame on the very first layout pass.

See [ADR-037](../adr/037-loader-success-state-and-paste-detection.md) for the rationale behind the fixed-frame pattern and the contextual message.

---

## Related

- [LLM Service API Reference](llm-service-api.md)
- [Database Schema Reference](database-schema.md)
- [App Settings Reference](app-settings.md)
- [Supported Models Reference](supported-models.md)
- [ADR-023: Supabase Auth Strategy](../adr/023-supabase-auth-strategy.md)
- [ADR-027: Supabase PostgreSQL over D1](../adr/027-supabase-postgres-over-d1.md)
- [ADR-033: Limit Reached Popup](../adr/033-limit-reached-popup-window.md)
- [ADR-034: Unlimited Pro Plan](../adr/034-unlimited-pro-plan.md)
- [ADR-037: Loader success state and paste detection](../adr/037-loader-success-state-and-paste-detection.md)
