# ADR-020: Slim base prompt — universal invariants only

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Reduce the base system prompt to exactly two universal invariants:

1. **Preservation rule** — "Preserve all original intent. Never add goals or requirements not present in the original."
2. **Output format rule** — "Output only the rewritten prompt. No preamble, no explanation, no wrapper tags. The first character of your response must be the first character of the rewritten prompt."

All content guidance, style direction, tone, structure, and output format decisions are now owned exclusively by the guideline profile (`{guidelines}`). The base prompt no longer contains any rules about ambiguity elimination, implicit requirements, filler phrases, or audience inference.

---

## Context

The previous base prompt contained nine rules covering:

- Preserve original intent
- Make implicit requirements explicit
- Eliminate ambiguity to a single valid interpretation
- Avoid filler phrases ("please", "could you", etc.)
- Infer audience context where missing
- Apply platform formatting after profile guidelines

These rules were added incrementally to fix specific failure modes observed during testing. Over time, the base prompt grew into a set of content and style instructions that overlapped heavily with what each guideline profile was also trying to express.

### The core problem: base prompt and profiles competed for the same space

Each built-in profile (`systemPrompt`) was written to tell the improving LLM what kind of output to produce. The base prompt simultaneously told the LLM how to handle ambiguity, implicit context, and filler phrases — instructions that sometimes contradicted or diluted the profile's intent.

**Concrete example**: The "Professional Email" profile says to include only context present in the original. The old base prompt said to "make all implicit requirements explicit" — directly in conflict. The LLM had to reconcile two opposing instructions on every call.

**Concrete example**: The "Summarize" profile specifies exact output format (TL;DR + bullets + length cap). Base prompt rules about filler phrases and single-interpretation prompts were irrelevant and added noise.

The consequence was unpredictable behaviour: profiles with strong, specific guidance were undermined by general-purpose rules in the base prompt. Profiles with weaker guidance relied on the base prompt to compensate, producing inconsistent results.

---

## Alternatives Considered

### A. Keep all nine rules, rewrite profiles to avoid conflicts

Rejected: requires auditing every profile (including future generated profiles) against all base rules. The conflict surface grows every time either side changes. Maintenance burden is unsustainable.

### B. Move all rules into each profile explicitly

Rejected: creates duplication across all profiles. Common behavior like output format (no preamble, first character rule) would need to be restated in every profile. The universal invariants are better owned by the base.

### C. Remove base prompt entirely; let profiles own everything (chosen partially)

Considered: clean separation. Rejected in full because two rules genuinely must apply universally:

- **Preservation** must always hold regardless of profile. A profile that does not mention preservation should not be interpreted as permission to invent goals. This cannot be delegated.
- **Output format** must always hold. Without it, every profile must explicitly say "output only the rewritten prompt" — which is a universal interface contract, not a style preference.

### D. Two universal invariants in base, profiles own everything else (chosen)

The two rules that are truly universal (preservation + output format) are the only rules that belong in the base prompt. Everything else — style, tone, content focus, structure, ambiguity handling — varies by use case and belongs in the profile.

---

## Three-Layer Architecture

`BasePrompt.build` composes the final system prompt in three layers:

```
Layer 1: Base prompt (universal invariants)
         — preservation rule
         — output format rule
         — {guidelines} placeholder

Layer 2: Profile guidelines (content + style)
         — injected at {guidelines} from GuidelineProfile.systemPrompt
         — fully owns: tone, structure, content focus, audience handling,
           ambiguity strategy, implicit context handling

Layer 3: Platform formatting (structural output)
         — appended after the base prompt when TargetPlatform != .generic
         — owns: XML tags, Markdown, section ordering, example formatting
```

Each layer has a distinct, non-overlapping responsibility:

| Layer | Responsibility | Changed by |
|-------|---------------|-----------|
| Base prompt | Output format + preservation | App developer |
| Profile guidelines | Content, tone, structure | Profile author or AI generator |
| Platform formatting | Target-assistant syntax | App developer per-platform |

---

## Profile Preservation Rule Alignment

Because the base prompt no longer enforces "do not infer missing context," every built-in profile now includes its own explicit preservation rule as a closing statement. This is the canonical form:

> "Include only context present in the original — do not invent [role-specific details] if not stated."

Where `[role-specific details]` is substituted with examples relevant to that profile (e.g., "the recipient, relationship, or objective" for Professional Email; "the document type, audience, or purpose" for Draft a Document).

This pattern is also enforced by `ProfileGeneratorService.metaPrompt` — AI-generated profiles are required to close with this rule, ensuring the invariant propagates to custom profiles.

---

## Fix: Claude platform formatting instruction

The previous Claude formatting instruction appended:
`"Use <thinking> and <answer> tags to separate reasoning from final output when multi-step reasoning is needed."`

This was incorrect: `<thinking>` and `<answer>` are Claude's internal response-time constructs for its own reasoning process, not prompt-side structuring tools. Including them in an improved prompt caused Claude to interpret the pasted result as AI-generated output rather than a user instruction. The instruction was removed.

---

## Consequences

- The base prompt is shorter and simpler. Less surface area for conflicts with profiles. ✓
- Profiles now fully own content decisions. Adding or modifying a profile does not require checking it against base prompt rules. ✓
- Every built-in profile explicitly states its own preservation rule, making each profile self-documenting and independently readable. ✓
- The output format contract (no preamble, first-character rule) remains universal and does not need to be restated in every profile. ✓
- Custom templates (`Defaults[.basePromptTemplate]`) must contain `{guidelines}`. The preservation and output format rules are embedded in the default template and will be lost if a user writes a custom template that omits them — an acceptable trade-off for the flexibility of custom templates.
- AI-generated profiles (ADR-019) include the preservation closing rule by construction via the meta-prompt requirement. ✓

---

## Related

- [ADR-013: `{guidelines}` placeholder in base prompt](013-base-prompt-placeholder.md)
- [ADR-016: Per-platform formatting instructions](016-target-platform-formatting.md)
- [ADR-018: Outcome-oriented built-in profiles](018-outcome-oriented-profiles.md)
- [ADR-019: AI-generated profiles](019-ai-generated-profiles.md)
- [Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md)
- [Data Models Reference — GuidelineProfile](../reference/data-models.md#guidelineprofile)
