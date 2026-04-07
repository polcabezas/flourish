# ADR-014: Save Draft on Dismiss, Not on Every Keystroke

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

The overlay draft (text typed but not submitted) is saved to UserDefaults only when the overlay is dismissed via Escape. It is not saved on every keystroke or after every word.

---

## Context

When a user opens the overlay, types a draft prompt, and dismisses it (Escape or hotkey toggle) without submitting, flourish saves the draft so it can be restored on the next overlay open. The question is: when should the save happen?

Two options:
1. **On every keystroke**: maximum safety — the draft is always up to date.
2. **On dismiss**: saves once, at the end of the interaction.

---

## Alternatives Considered

### Save on every keystroke
`onChange(of: viewModel.inputText)` → `UserDefaults.standard.set(text, forKey: "flourish.overlayDraft")`

Pros:
- Draft is preserved even if the app crashes mid-typing.
- No edge cases around what "dismiss" means.

Cons:
- `UserDefaults` writes on every character typed. On modern hardware this is imperceptibly fast, but it's still unnecessary I/O.
- UserDefaults is not designed for high-frequency writes. The OS batches `synchronize()` calls, but triggering it frequently can cause visible latency in edge cases.
- The draft persists even when the user is in the middle of typing — restoring a half-typed word from a previous session could be confusing.

Rejected.

### Save on a debounced timer
Save 1-2 seconds after the user stops typing. More conservative than every-keystroke. Still adds background activity. Overkill for the use case. Rejected.

---

## Decision Rationale

The draft persistence exists for a specific scenario: the user types a thoughtful prompt, gets distracted, dismisses the overlay, and wants it back when they open it again. This scenario does not require character-level precision — saving the state at dismiss time is sufficient.

Implementation:
```swift
func dismiss(paste: Bool) {
    let text = overlayViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !paste && !text.isEmpty {
        UserDefaults.standard.set(text, forKey: "flourish.overlayDraft")
        UserDefaults.standard.set(Date(), forKey: "flourish.overlayDraftDate")
    } else if paste {
        // Clear draft after successful paste
        UserDefaults.standard.removeObject(forKey: "flourish.overlayDraft")
        UserDefaults.standard.removeObject(forKey: "flourish.overlayDraftDate")
    }
    
    panel.orderOut(nil)
}
```

The draft is also cleared after a successful paste — there's no reason to restore a prompt that was already improved and pasted.

---

## Consequences

- UserDefaults is written once per dismiss event, not per keystroke. ✓
- Draft is preserved across app restarts for the "distracted user" scenario. ✓
- If the app crashes while the overlay is open, the draft is NOT saved. Acceptable — crashes are rare and mid-typing drafts are typically short.
- Successful pastes clear the draft — prevents stale prompts appearing on the next open. ✓
- Draft saved at dismiss time is displayed with a timestamp ("Draft from X hours ago") to set user expectations. ✓

---

## Related

- [App Settings Reference](../reference/app-settings.md) — `flourish.overlayDraft` and `flourish.overlayDraftDate` keys
- [Prompt Improvement Workflow Explanation](../explanation/prompt-improvement-workflow.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
