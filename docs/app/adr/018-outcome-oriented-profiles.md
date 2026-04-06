# ADR-018: Outcome-oriented built-in profiles for non-technical users

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Replace the six prompt-quality-dimension built-in profiles (Clearer, More Concise, More Detailed, Professional, Developer, Creative) with six outcome-oriented profiles (Professional Email, Summarize, Explain Simply, Draft a Document, Analyze & Advise, Brainstorm) designed for office professionals who are not prompt engineers.

---

## Context

The original built-in profiles optimised abstract qualities of the prompt itself — clarity, conciseness, detail level. This framing assumes the user thinks about their prompts as objects to be engineered, which is not true of the target audience: marketing managers, legal assistants, project managers, and other professionals who use AI to get work done.

The core insight: **a non-technical user cares about what comes back from the AI, not about the structural quality of their input prompt.** A prompt that "asks for a clear explanation" produces a better response than a prompt that has been made "clearer" in the abstract.

---

## Alternatives Considered

### A. Keep quality-dimension profiles, add use-case profiles alongside them

Rejected because it grows the picker to 12+ items and forces users to understand the difference between meta-categories (what does "Clearer" mean vs "Explain Simply"?).

### B. Make profiles fully user-defined with no built-ins

Rejected because new users have no starting point and the value of the app is not immediately apparent without working examples.

### C. Outcome-oriented profiles (chosen)

Each profile's `systemPrompt` instructs the improving LLM to rewrite the user's prompt so that the target AI produces a specific professional output format — email, summary, explanation, document, analysis, or idea list. The profile name is the output format the user recognises from their work, not a prompt engineering concept.

---

## Consequences

- `GuidelineProfile.builtins` is completely replaced. The six new profiles have new stable UUIDs (`00000000-0000-0000-0000-000000000001` through `...000006`), so the old UUIDs are abandoned.
- `AppDelegate.applicationDidFinishLaunching` re-seeds built-in profiles on every launch to keep them in sync with the code. User-created profiles are preserved.
- Any user who had selected an old built-in profile will fall back to the first available profile on next open — an acceptable one-time disruption during this pre-release phase.
- The "Developer" built-in is removed. Technical users can generate or manually create a custom profile for their specific engineering context.

---

## Related

- [Data Models Reference — GuidelineProfile](../reference/data-models.md#guidelineprofile)
- [How-To: Manage Profiles](../how-to/manage-profiles.md)
- [ADR-019: AI-generated profiles](019-ai-generated-profiles.md)
