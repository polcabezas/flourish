# App Settings Reference

All `Defaults.Key` definitions used by Flourish, their types, default values, and purpose.

Defined in `Flourish/Core/AppSettings.swift`. Accessed via the `Defaults` package's `@Default` property wrapper in views, or `Defaults[.keyName]` in services.

**Note:** All provider-related settings keys (`openRouterEnabled`, `openRouterModel`, `groqEnabled`, `groqModel`, `activeProvider`, etc.) were removed when the app moved to the Cloudflare Worker proxy architecture (ADR-015). Provider and model are now configured in `cloudflare/wrangler.toml`, not in the app.

---

## Profile Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `profiles` | `[GuidelineProfile]` | `[]` | All user-created custom profiles (JSON-encoded) |
| `lastSelectedProfileId` | `String` | `""` | UUID string of the last selected profile. Empty string means "use first available" |
| `targetPlatform` | `TargetPlatform` | `.generic` | Last selected target platform (Claude, ChatGPT, Gemini, Perplexity, or Universal). Appends platform-specific formatting instructions to the base prompt. Persisted across sessions |

---

## Statistics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `totalRequestCount` | `Int` | `0` | Cumulative number of successful LLM requests |
| `totalTokensIn` | `Int` | `0` | Cumulative prompt tokens sent |
| `totalTokensOut` | `Int` | `0` | Cumulative completion tokens received |
| `totalCostUSD` | `Double` | `0.0` | Cumulative estimated cost in USD |

---

## Base Prompt

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `basePromptTemplate` | `String` | `""` | Custom system prompt template. Must contain `{guidelines}` for profile injection. Empty string means use the built-in default template from `BasePrompt.swift`. **Not exposed in the Settings UI** (removed in ADR-021). |

---

## General Preferences

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `launchAtLogin` | `Bool` | `false` | Whether to register as a login item via `LaunchAtLogin` |
| `showDockIcon` | `Bool` | `false` | Whether to set activation policy to `.regular` (shows Dock icon). Default is `.accessory` (menu bar only) |

---

## Draft (Not Defaults package — raw UserDefaults)

These two keys are written directly to `UserDefaults.standard`, not through the `Defaults` package:

| Key | Type | Description |
|-----|------|-------------|
| `flourish.overlayDraft` | `String` | The text in the overlay when it was last dismissed without pasting |
| `flourish.overlayDraftDate` | `Date` | Timestamp of when the draft was saved |

---

## Reading and Writing

### In SwiftUI views

```swift
@Default(.lastSelectedProfileId) var lastSelectedProfileId: String
```

### In services / controllers

```swift
// Read:
let profileId = Defaults[.lastSelectedProfileId]

// Write:
Defaults[.totalRequestCount] += 1
```

---

## Related

- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [Data Models Reference](data-models.md) — `GuidelineProfile` definition
- [ADR-004: Defaults Package](../adr/004-defaults-package.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md) — explains removal of provider keys
- [ADR-021: Remove base prompt editor](../adr/021-remove-base-prompt-editor.md) — explains why `basePromptTemplate` is no longer UI-exposed
