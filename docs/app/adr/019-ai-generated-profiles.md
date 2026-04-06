# ADR-019: AI-generated guideline profiles

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Add a `ProfileGeneratorService` that calls the Flourish proxy LLM with a meta-prompt to generate a custom `GuidelineProfile` (name + `systemPrompt`) from a plain-language description of the user's role and tasks. The generated profile is presented for review and editing before saving.

---

## Context

Even with six well-designed outcome-oriented built-ins (ADR-017), a marketing manager writing brand copy and a legal assistant drafting regulatory responses have fundamentally different needs that no fixed profile set can cover. The most useful profile for any user is one tailored to their specific job and context.

Rather than requiring users to write a system prompt from scratch — which demands understanding of how the prompt pipeline works — the app lets them describe their work in plain language and generates the profile for them.

---

## Alternatives Considered

### A. No generated profiles — users write their own

Rejected: requires understanding of the `{guidelines}` contract and how prompts compose. The target audience is explicitly non-technical.

### B. New `/generate-profile` Cloudflare Worker endpoint

Rejected: requires worker redeployment, adds a new route, and creates an asymmetry in the API surface. The `/improve` endpoint already accepts an arbitrary `systemPrompt` — the same infrastructure can generate a profile by sending a meta-prompt as the system message.

### C. Reuse `/improve` with a meta-prompt (chosen)

`ProfileGeneratorService` calls `FlourishProxyService.improvePrompt(_:systemPrompt:model:)` with:
- `text` = the user's role/task description  
- `systemPrompt` = a hardcoded meta-prompt instructing the LLM to produce `{ "name": "...", "systemPrompt": "..." }` JSON

The response is stripped of any markdown code fences and decoded as JSON into a `GuidelineProfile`. No new infrastructure required.

---

## Two-stage UI

The `GenerateProfileSheet` presents two stages within a single modal:

1. **Describe** — text area for role/task description + Generate button with loading state
2. **Review** — pre-filled name and guidelines editor + Back (to re-describe) + Save

The user can edit both the generated name and the generated guidelines before saving. This is consistent with the existing `ProfileEditSheet` flow for manual profiles.

---

## Consequences

- `ProfileGeneratorService` is a non-singleton service instantiated per generation call. It holds no state.
- Generation failures (network error, JSON parse error, LLM rate limit) surface as error text in the Describe stage — the user can retry without re-entering their description.
- The meta-prompt is a hardcoded string in `ProfileGeneratorService.metaPrompt`. Improving the quality of generated profiles is a code change, not a configuration change.
- Generated profiles are indistinguishable from manually created profiles once saved: `isBuiltin == false`, full CRUD available.
- The LLM may occasionally produce a profile that does not follow the outcome-oriented pattern. The review stage exists precisely to catch and correct this before saving.

---

## Related

- [LLM Service API Reference](../reference/llm-service-api.md)
- [How-To: Manage Profiles](../how-to/manage-profiles.md)
- [ADR-018: Outcome-oriented profiles](018-outcome-oriented-profiles.md)
- [ADR-015: Cloudflare Worker proxy](015-cloudflare-worker-proxy.md)
