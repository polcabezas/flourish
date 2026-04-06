# ADR-021: Remove base prompt editor from Settings UI

**Status:** Accepted  
**Date:** 2026-04-06

---

## Decision

Remove the **Base Prompt** section from `SettingsPanelView`. Users can no longer view or edit `Defaults[.basePromptTemplate]` from within the app.

The `basePromptTemplate` key and the fallback logic in `BasePrompt.build` are retained in the codebase; the key is simply not exposed in any UI surface. The hardcoded default in `BasePrompt.swift` is always active.

---

## Context

`SettingsPanelView` had three sections: **Shortcut**, **Base Prompt**, and **General**. The Base Prompt section rendered a full `TextEditor` pre-filled with `BasePrompt.defaultTemplate` as placeholder text, a "Reset to Default" button, and a validation warning when `{guidelines}` was missing.

### Why the editor was added

The editor was introduced early in development as a power-user escape hatch: if the built-in base prompt produced poor output for a particular workflow, users could override it. It was positioned alongside the `{guidelines}` placeholder mechanism (ADR-013).

### Why it is now being removed

**ADR-020 made the base prompt stable and minimal.** After slimming the base prompt to two universal invariants (preservation + output format), the template is short and generic — it no longer contains any content or style rules that a user would want to tune. All customisation of output style now belongs in guideline profiles (ADR-018, ADR-019), not in the base prompt.

**The editor surface offered poor safety guarantees.** A user who accidentally removed `{guidelines}` from their custom template silently disabled all profile guidelines on every request. The validation warning in the UI helped, but it was easy to miss and could not prevent the silent failure at runtime.

**The settings panel is simpler and less error-prone without it.** The profiles system (create, edit, generate with AI) is the correct mechanism for customising Flourish's output behaviour. The base prompt editor created a second, less visible configuration surface for the same concern.

---

## Alternatives Considered

### A. Keep the editor; restrict it to an advanced/developer section

Rejected: there is no legitimate use case for a non-developer user to edit the base prompt after ADR-020. Making it harder to reach but still present would add complexity without proportionate benefit.

### B. Replace the editor with a read-only preview

Rejected: the default template is short and stable enough that it does not need a dedicated UI element for discovery. A developer who needs to inspect it can read `BasePrompt.swift` directly.

### C. Remove the editor and deprecate the `basePromptTemplate` key

Considered but not chosen: the key and fallback logic in `BasePrompt.build` are preserved for forward compatibility. If a future version re-exposes editing (e.g., a developer-mode setting), the storage layer is already in place. Removing the key now would constitute a silent data migration with no benefit.

---

## Consequences

- **`SettingsPanelView` now has two sections:** Shortcut and General. ✓
- **The `BasePromptSection` struct is deleted** from `SettingsPanelView.swift`. ✓
- **`Defaults[.basePromptTemplate]` continues to exist** and is read by `BasePrompt.build`. Any value previously stored persists in `UserDefaults` but is now unreachable from the UI.
- **Users who had customised the base prompt** will have their stored value silently ignored if they cleared the field before this update — or will continue to use their custom value if they set one, since `BasePrompt.build` still prefers a non-empty stored value over the default. This edge case is acceptable: the base prompt is now considered an internal concern.
- The settings panel is narrower in scope, reducing the cognitive surface of the app. ✓

---

## Related

- [ADR-013: `{guidelines}` placeholder in base prompt](013-base-prompt-placeholder.md)
- [ADR-018: Outcome-oriented built-in profiles](018-outcome-oriented-profiles.md)
- [ADR-019: AI-generated profiles](019-ai-generated-profiles.md)
- [ADR-020: Slim base prompt — universal invariants only](020-slim-base-prompt-invariants-only.md)
- [App Settings Reference](../reference/app-settings.md) — `basePromptTemplate` key
