# ADR-035: `.contentShape(Rectangle())` for plain-button hit areas

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

When a `Button` uses `.buttonStyle(.plain)` and its label contains padding, a background shape, or a clip shape, add `.contentShape(Rectangle())` (or an appropriate shape) as the **last modifier inside the label view** to make the full padded area hit-testable.

---

## Context

In `AccountView.swift`, `PlanBillingToggle` renders a segmented toggle for billing-period selection (Monthly / Annual) using a `ForEach` over `BillingPeriod.allCases`. Each segment is a `Button` with `.buttonStyle(.plain)`:

```swift
Button { selected = period } label: {
    Text(period.rawValue)
        .font(.flourishButton)
        .foregroundColor(selected == period ? .flourishTextPrimary : .flourishTextSecondary)
        .padding(.horizontal, FS.xxl)
        .padding(.vertical, FS.sm)
        .background(...)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
        .shadow(...)
}
.buttonStyle(.plain)
.pointerCursor()
```

On macOS, SwiftUI with `.buttonStyle(.plain)` uses the label's **content shape** — not its visual frame — as the hit-test region. The content shape defaults to the bounding box of the label's actual content (i.e., the `Text`). Padding, background fills, and clip shapes are visual-only modifiers; they do not expand the hit-test region. As a result, only the text characters themselves registered clicks. Tapping anywhere in the padded area around the text had no effect.

This is the same class of bug documented in [ADR-030](030-plans-billing-ui.md) for the "Upgrade to Pro" button, which fixed the content-shape issue on that specific button. ADR-035 captures the general pattern and its application to `PlanBillingToggle`.

---

## Fix

Add `.contentShape(Rectangle())` as the last modifier inside the label, after all visual modifiers:

```swift
Button { selected = period } label: {
    Text(period.rawValue)
        .font(.flourishButton)
        .foregroundColor(selected == period ? .flourishTextPrimary : .flourishTextSecondary)
        .padding(.horizontal, FS.xxl)
        .padding(.vertical, FS.sm)
        .background(...)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
        .shadow(...)
        .contentShape(Rectangle())   // ← expands hit-test region to full padded frame
}
.buttonStyle(.plain)
.pointerCursor()
```

`Rectangle()` is used rather than a `RoundedRectangle` because hit-test precision at the corners of a small toggle segment is not perceptible; a plain rectangle avoids the cost of computing rounded-corner containment on every hit test.

---

## Why `.contentShape` must be inside the label

SwiftUI resolves the hit-test region of a `Button` with `.buttonStyle(.plain)` from the **label's content shape**, not from the outer `Button` view. Applying `.contentShape(...)` on the `Button` itself (outside the label) has no effect with `.plain` style. The modifier must appear inside the label closure, after all padding and visual modifiers.

This is the same rule documented in ADR-030 § "Button hit-area fix":

> The fix is to add `.contentShape(RoundedRectangle(cornerRadius: FS.radiusMd))` as the **last modifier inside the label**, after `.clipShape`.

---

## Alternatives Considered

| Alternative | Reason rejected |
|-------------|-----------------|
| Switch to `.bordered` or another built-in button style | Built-in styles impose visual chrome that conflicts with the segmented-toggle design |
| Wrap in a `ZStack` with an invisible `Rectangle().fill(.clear)` | Works but is more verbose than `.contentShape` and non-idiomatic |
| Apply `.contentShape` on the outer `Button` | Has no effect with `.buttonStyle(.plain)` on macOS |

---

## Consequences

- The full padded area of each segment in `PlanBillingToggle` is now clickable.
- This pattern — `.contentShape(Rectangle())` as the last modifier inside a `.plain`-styled button label — is now the documented standard for all hit-area expansions in the flourish design system. See [Design System Reference § Interactive State Conventions](../reference/design-system.md#interactive-state-conventions).
- Developers adding new `.buttonStyle(.plain)` buttons with padding or custom backgrounds must follow this pattern.

---

## Related

- [ADR-030: Plans and Billing UI](030-plans-billing-ui.md) — first documented the `.contentShape` fix for the "Upgrade to Pro" button in the same `AccountView`
- [Design System Reference](../reference/design-system.md) — Interactive State Conventions
