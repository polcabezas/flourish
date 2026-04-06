# ADR-013: `{guidelines}` Placeholder in Base Prompt Template

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

The base system prompt template uses a `{guidelines}` placeholder string. `BasePrompt.build(profile:)` substitutes this placeholder with the selected guideline profile's `systemPrompt` text at call time. Users can also provide a custom base template in Settings, which must also contain `{guidelines}`.

---

## Context

Flourish needs to send a system prompt to the LLM that:
1. Establishes the base behavior (act as a prompt engineer, return only the improved prompt, etc.)
2. Incorporates the selected guideline profile's specific instructions.

These two concerns are separable:
- The base behavior is stable and shared across all profiles.
- The profile instructions vary per-selection and per-user.

The question is how to compose them.

---

## Alternatives Considered

### Concatenate base prompt + profile instructions
Simply append the profile text to the base prompt: `base + "\n" + profile.systemPrompt`. Simple, but gives no control over where the guidelines appear within the base structure. Some base prompts may want guidelines at the beginning; others at the end. Rejected.

### Separate `system` and `user` messages
Put base instructions in the `system` role message, profile instructions in the `user` role message. Reduces the coherence of the combined instruction. Some models respond differently to instruction placement. Rejected.

### Template engine (Mustache, Stencil)
Use a full template engine for the system prompt. Unnecessary complexity for a single substitution. Rejected.

---

## Decision Rationale

A single `{guidelines}` placeholder in the base template:
- Allows the base prompt author (or the user customizing the template) to choose exactly where profile-specific instructions appear within the overall prompt structure.
- Is trivially implemented with `String.replacingOccurrences(of: "{guidelines}", with: profile.systemPrompt)`.
- Is self-documenting — anyone reading the template can see where the profile instructions go.
- Validates easily: if the user's custom template lacks `{guidelines}`, Settings can warn them.

```swift
enum BasePrompt {
    static let defaultTemplate = """
    You are an expert prompt engineer. Your task is to improve the user's prompt
    while preserving their intent. Apply the following guidelines:
    
    {guidelines}
    
    Return only the improved prompt. Do not explain your changes.
    """
    
    static func build(profile: GuidelineProfile?) -> String {
        let template = Defaults[.basePromptTemplate].isEmpty
            ? defaultTemplate
            : Defaults[.basePromptTemplate]
        
        let guidelines = profile?.systemPrompt ?? ""
        return template.replacingOccurrences(of: "{guidelines}", with: guidelines)
    }
}
```

---

## Consequences

- Profile instructions are injected at the exact position in the system prompt that the template author designed. ✓
- Users can write custom base templates for advanced use cases (e.g., a multi-language template that includes instructions in French). ✓
- Settings validates that custom templates contain `{guidelines}` and warns if missing. ✓
- The `{guidelines}` syntax is simple enough that users can understand it without documentation. ✓
- If a profile with an empty `systemPrompt` is selected, `{guidelines}` becomes an empty string — the LLM receives the base prompt without any specific guidelines. Acceptable default behavior. ✓

---

## Related

- [LLM Service API Reference](../reference/llm-service-api.md) — system prompt assembly section
- [Create a Custom Profile Tutorial](../tutorials/create-custom-profile.md)
- [App Settings Reference](../reference/app-settings.md) — `basePromptTemplate` key
