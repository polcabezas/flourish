# ADR-016: Per-platform formatting instructions appended to the base prompt

**Status:** Accepted

---

## Decision

Add a `TargetPlatform` enum to the app with cases for the major AI assistants (Claude, ChatGPT, Gemini, Perplexity) plus a `generic` catch-all. Expose a picker in the overlay toolbar. When a non-generic platform is selected, `BasePrompt.build` appends a platform-specific multi-line formatting instruction to the system prompt before the LLM call.

---

## Context

Different AI assistants respond best to different prompt structures:

- **Claude** favours explicit XML tags (`<task>`, `<context>`) with rationale stated alongside constraints.
- **ChatGPT (GPT-4o)** benefits from Markdown structure and repeating the key constraint at the end to counteract recency bias.
- **Gemini** works best with a `<context>` XML wrapper, with the question placed last.
- **Perplexity** drives a live web search — the prompt should look like a keyword-rich expert query, not a conversational instruction.

Users typically know which assistant they will paste into. Providing platform-aware output from flourish eliminates a manual reformatting step and produces better results from the target model.

---

## Alternatives considered

### A. No platform targeting (status quo)

The improving LLM uses the profile guidelines only. Users who want platform-specific formatting must encode it in their custom profiles.

**Rejected because:** It places the burden on the user, requires duplicating profile variants for each platform, and is not discoverable for new users.

### B. Separate guideline profiles per platform

Ship built-in profiles like "Claude — Professional" and "ChatGPT — Developer".

**Rejected because:** It explodes the profile list (N platforms × M styles), makes profile management unwieldy, and conflates style intent (profile) with structural format (platform).

### C. Platform selection stored per-profile

Each `GuidelineProfile` carries a `targetPlatform` field.

**Rejected because:** A user often applies the same style profile (e.g. "More Concise") across multiple platforms in the same session. Forcing a platform on a profile defeats the point of the lightweight overlay workflow.

---

## Consequences

- `TargetPlatform.swift` adds a new model with `formattingInstruction: String?` computed from hardcoded strings. Updating these strings (e.g. as platform prompt guidelines evolve) requires a new app release.
- `BasePrompt.build` gains a `targetPlatform` parameter with a default of `.generic`, maintaining backward compatibility with any call site that omits it.
- `AppSettings` gains a `targetPlatform` key persisted via the Defaults package. The last selection is restored on next open.
- The overlay toolbar gains one additional control. Width remains fixed at 640pt; the toolbar row is `HStack` and accommodates the additional picker without layout changes.
- No change to the Cloudflare Worker or the LLM API call shape — the formatting instruction is part of the `systemPrompt` field already sent to the Worker.

---

## Related

- [ADR-013: `{guidelines}` placeholder in base prompt](013-base-prompt-placeholder.md)
- [ADR-015: Cloudflare Worker proxy](015-cloudflare-worker-proxy.md)
- [ADR-020: Slim base prompt — universal invariants only](020-slim-base-prompt-invariants-only.md)
- [Data Models Reference — TargetPlatform](../reference/data-models.md#targetplatform)
- [Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md)
