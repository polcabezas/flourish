# ADR-013: `{guidelines}` Placeholder in Base Prompt Template

**Status:** Accepted (partially superseded by ADR-020 for the default template content)  
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
- Is trivially implemented with `String.replacingOccurrences(of: "{guidelines}", with: guidelines)`.
- Is self-documenting — anyone reading the template can see where the profile instructions go.
- Validates easily: if the user's custom template lacks `{guidelines}`, Settings can warn them.

```swift
enum BasePrompt {
    static let defaultTemplate = """
    You are an expert prompt engineer. Your sole task is to rewrite the user's raw prompt \
    into a higher-quality version that will produce the best possible response from an AI model.

    Apply the following profile guidelines to the content and style of the rewrite:

    <guidelines>
    {guidelines}
    </guidelines>

    Governing rules — these always apply:
    - Preserve every original intent, requirement, and constraint. Never introduce information, \
      goals, or requirements not present in the original.
    - Make all implicit requirements explicit without changing the core ask.
    - Eliminate ambiguity so the prompt has exactly one valid interpretation.
    - Do not add filler phrases ("please", "could you", "I need you to") — write direct, \
      purposeful instructions.
    - If platform-specific formatting instructions follow below, apply them to the structure \
      of the output after applying the profile guidelines above.

    Output only the rewritten prompt. Start with its first word — no preamble, no explanation, \
    no meta-commentary.
    """

    static func build(guidelines: String, targetPlatform: TargetPlatform = .generic) -> String {
        let stored = Defaults[.basePromptTemplate].trimmingCharacters(in: .whitespaces)
        let active = stored.isEmpty ? defaultTemplate : stored
        var prompt = active.replacingOccurrences(of: "{guidelines}", with: guidelines)
        if let instruction = targetPlatform.formattingInstruction {
            prompt += "\n\n" + instruction
        }
        return prompt
    }
}
```

### Why the governing rules were added

The default template was extended with five explicit governing rules after early testing revealed common failure modes:

| Rule | Failure it prevents |
|------|---------------------|
| Preserve original intent | LLM subtly rewrites the task rather than the expression |
| Make implicit explicit | LLM produces output that doesn't capture unstated requirements |
| Eliminate ambiguity | LLM tolerates multiple valid interpretations |
| No filler phrases | LLM adds "Please kindly…" preamble that degrades prompt quality on all platforms |
| Platform instructions ordering | LLM applies platform format before style guidelines, conflating the two layers |

The final sentence (`"Start with its first word"`) is more actionable than the former `"Return only the rewritten prompt"` and closes the gap on what "no preamble" means.

### Two-layer composition

`build` composes the system prompt in two layers:

1. **Style layer** — `{guidelines}` substituted from the selected `GuidelineProfile.systemPrompt`
2. **Format layer** — `TargetPlatform.formattingInstruction` appended after a blank line when non-`nil`

The governing rules make this order explicit to the improving LLM ("apply platform-specific formatting instructions… after applying the profile guidelines above"), preventing the LLM from conflating style and structure when both are present.

---

## Consequences

- Profile instructions are injected at the exact position in the system prompt that the template author designed. ✓
- Users can write custom base templates for advanced use cases (e.g., a multi-language template that includes instructions in French). ✓
- Settings validates that custom templates contain `{guidelines}` and warns if missing. ✓
- The `{guidelines}` syntax is simple enough that users can understand it without documentation. ✓
- If a profile with an empty `systemPrompt` is selected, `{guidelines}` becomes an empty string — the LLM receives the base prompt without any specific guidelines. Acceptable default behavior. ✓

---

## Related

- [ADR-020: Slim base prompt — universal invariants only](020-slim-base-prompt-invariants-only.md) — supersedes the specific default template content documented here
- [LLM Service API Reference](../reference/llm-service-api.md) — system prompt assembly section
- [Create a Custom Profile Tutorial](../tutorials/create-custom-profile.md)
- [App Settings Reference](../reference/app-settings.md) — `basePromptTemplate` key
