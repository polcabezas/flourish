# App Settings Reference

All `Defaults.Key` definitions used by Flourish, their types, default values, and purpose.

Defined in `Flourish/Core/AppSettings.swift`. Accessed via the `Defaults` package's `@Default` property wrapper in views, or `Defaults[.keyName]` in services.

---

## Provider Settings

### OpenRouter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `openRouterEnabled` | `Bool` | `false` | Whether OpenRouter is enabled and visible in pickers |
| `openRouterModel` | `String` | `"google/gemini-2.0-flash-001"` | Selected model ID for OpenRouter requests |
| `openRouterCustomModels` | `[String]` | `[]` | User-added custom model IDs for OpenRouter |

### Groq

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `groqEnabled` | `Bool` | `false` | Whether Groq is enabled and visible in pickers |
| `groqModel` | `String` | `"llama-3.3-70b-versatile"` | Selected model ID for Groq requests |
| `groqCustomModels` | `[String]` | `[]` | User-added custom model IDs for Groq |

### Active Provider

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `activeProvider` | `String` | `"openrouter"` | Raw value of the active `LLMProvider` enum case. Read via `Defaults.activeProviderEnum` computed property |

---

## Profile Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `profiles` | `[GuidelineProfile]` | `[]` | All user-created custom profiles (JSON-encoded) |
| `lastSelectedProfileId` | `String` | `""` | UUID string of the last selected profile. Empty string means "use first available" |

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
| `basePromptTemplate` | `String` | `""` | Custom system prompt template. Must contain `{guidelines}` for profile injection. Empty string means use the built-in default template from `BasePrompt.swift` |

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
@Default(.openRouterEnabled) var openRouterEnabled: Bool

// Reads and writes automatically:
Toggle("Enable OpenRouter", isOn: $openRouterEnabled)
```

### In services / controllers

```swift
// Read:
let model = Defaults[.openRouterModel]

// Write:
Defaults[.totalRequestCount] += 1
```

### Computed property: active provider enum

`AppSettings.swift` provides a convenience extension:

```swift
extension Defaults {
    static var activeProviderEnum: LLMProvider {
        get { LLMProvider(rawValue: Defaults[.activeProvider]) ?? .openRouter }
        set { Defaults[.activeProvider] = newValue.rawValue }
    }
}
```

---

## Related

- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [Data Models Reference](data-models.md) — `GuidelineProfile` definition
- [ADR-004: Defaults Package](../adr/004-defaults-package.md)
