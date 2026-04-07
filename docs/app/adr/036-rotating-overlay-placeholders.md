# ADR-036: Rotating playful placeholders in the overlay input

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Replace the static `"Write your prompt…"` placeholder in `OverlayView` with a randomised selection drawn from a pool of 25 short, playful strings. A new index is picked with `Int.random(in:)` on both `onAppear` and `onChange(of: focusTrigger)`, so each overlay open shows a fresh line. The placeholder `Text` is layered **on top of** the `TextEditor` in the `ZStack` (with `allowsHitTesting(false)`) so it remains visible when the field is focused but empty.

---

## Context

The overlay is the primary interaction surface of flourish. A single static placeholder carries no personality and does not communicate the app's permissive, low-friction tone ("rough drafts welcome"). Product copy that varies on each open creates a subtle sense of aliveness without any continuous animation or maintenance overhead.

The placement change (placeholder on top, not behind, the `TextEditor`) also fixes a pre-existing bug: `TextEditor`'s internal `NSTextView` rendered an opaque background at focus time, hiding the `Text` sitting underneath it in the `ZStack`.

---

## Alternatives Considered

### A. Keep static placeholder, improve the copy

Rejected: a single string must be both instructional and playful — an awkward constraint. A rotating pool lets different strings serve different moods without compromising either goal.

### B. Animated typewriter effect cycling through phrases

Rejected: continuous animation draws attention away from the user's own text and adds unnecessary `Timer` / `withAnimation` complexity.

### C. Context-aware placeholders (last-used profile, time of day, etc.)

Rejected as premature. The randomised pool already provides sufficient variety. Context-awareness can be layered on later if there is user demand.

---

## Consequences

- **`OverlayView.swift`:** `placeholderIndex: @State` initialised to `0`; `onAppear` and `onChange(of: focusTrigger)` both re-randomise it on every open. `ZStack` order is `TextEditor` → `Text` (placeholder on top).
- **Copy pool:** 25 strings defined as `static let placeholders`. Adding or removing strings requires only editing that array; no other code changes.
- **Design system:** No new tokens. Placeholder uses `.flourishInput` font and `flourishTextSecondary.opacity(0.5)` — intentionally dimmer than body text to stay unobtrusive.

---

## Related

- [ADR-001: Non-activating NSPanel for the overlay](001-non-activating-panel.md)
- [ADR-017: NSHostingController for the overlay panel](017-nshosting-controller-for-overlay.md)
