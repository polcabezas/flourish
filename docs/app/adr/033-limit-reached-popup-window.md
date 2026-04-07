# ADR-033: Separate floating popup for monthly limit reached UI

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

When a user hits the free-plan monthly limit, show a separate bottom-center floating `NSPanel` (`LimitReachedWindowController`) rather than replacing the overlay's content in-place.

---

## Context

The original design embedded a `LimitReachedView` inside the overlay panel: when the limit error arrived, the overlay's input content was hidden and an upgrade prompt shown instead. This caused two problems:

1. The overlay panel is an `NSPanel` with `.nonactivatingPanel` — it must never steal focus. Showing an upgrade CTA inside it means users can't interact with it normally (no Cmd+W, no natural window management).
2. Dismissing the upgrade view required careful state restoration (re-show the draft, reset `limitReached` flag) — the logic was error-prone and coupled error handling to view state.

A separate, independently-managed popup window removes all of this coupling.

---

## Alternatives Considered

### A. In-overlay replacement (original approach)

`OverlayViewModel` published `limitReached: Bool`. `OverlayView` swapped its content to `LimitReachedView(plan:limit:onUpgrade:onDismiss:)`. Draft was restored on dismiss.

Rejected: couples error handling to overlay view state; the overlay must remain a pure input surface; UX felt abrupt (the input surface transformed into an upgrade prompt mid-flow).

### B. NSAlert sheet

Simple native modal alert with an "Upgrade" button.

Rejected: an alert blocks all interaction and feels aggressive for a soft limit. The Wispr Flow-style toast popup is far less intrusive.

### C. Separate floating panel (chosen)

`LimitReachedWindowController` (singleton, `@MainActor`) manages a borderless `NSPanel`:
- Positioned bottom-center of the main screen, 32 pt above the dock.
- 400 × 170 pt, floating level, `nonactivatingPanel` so it never steals focus.
- Displays `LimitReachedPopupView` — a split layout with copy + CTA on the left, a branded green panel on the right.
- Auto-dismisses after 12 seconds via a `Timer.publish` in the view; the right panel shows a draining circular progress ring so the user knows it will disappear.
- Plays `Breeze.aiff` on show (retained in `breezeSound` to outlive the async playback).

`OverlayWindowController.showError()` simply calls `LimitReachedWindowController.shared.show()` after saving the draft. No overlay state changes are needed.

### NSHostingView clear background (required)

After setting up the `NSHostingController`, its view must have its background explicitly cleared:

```swift
hosting.view.wantsLayer = true
hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
```

Without this, AppKit gives the hosting view a default opaque background that bleeds outside the SwiftUI `clipShape(RoundedRectangle(cornerRadius: 16))`, appearing as a dark rectangular border around the card. The `NSPanel` itself is already `backgroundColor = .clear, isOpaque = false` — the hosting view must match.

### Upgrade button style

The "Upgrade" button uses `cornerRadius(FS.radiusSm)` (6 pt) — the same radius used for all primary action buttons in the app — not a `Capsule`. This keeps it visually consistent with the design system.

---

## Consequences

- `LimitReachedWindowController.swift` and `LimitReachedView.swift` are new files; add to XcodeGen sources via the existing `path: flourish` glob.
- `flourish/Sounds/Breeze.aiff` must be included in the app bundle; declared as a resource in `project.yml` under `flourish/Sounds`.
- `OverlayViewModel` no longer needs `limitReached`, `showLimitReached`, or `dismissLimitReached`.
- `OverlayView` no longer conditionally renders `LimitReachedView`.
- The upgrade CTA in `LimitReachedPopupView` opens the Account section via `MainWindowController.shared.showAndFocus(section: .account)`.

---

## Related

- [ADR-001: Non-activating NSPanel for the overlay](001-non-activating-panel.md)
- [ADR-007: Singleton window controllers](007-singleton-window-controllers.md)
- [ADR-030: Plans and Billing UI](030-plans-billing-ui.md)
- [ADR-034: Unlimited improvements for the Pro plan](034-unlimited-pro-plan.md)
