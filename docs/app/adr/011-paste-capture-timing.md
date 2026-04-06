# ADR-011: Capture Previous App Before Showing Overlay

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

`PasteService.capturePreviousApp()` must be called before `OverlayPanel.makeKeyAndOrderFront(_:)` in the overlay show sequence.

---

## Context

`PasteService.capturePreviousApp()` reads `NSWorkspace.shared.frontmostApplication` to get a reference to the app the user was in when they pressed the hotkey. This reference is used later to:
1. Reactivate that app after the LLM call completes.
2. Target the synthetic Cmd+V keystroke at it.

The ordering matters:
- `NSWorkspace.shared.frontmostApplication` returns the current frontmost application.
- Even though `NSPanel` with `.nonactivatingPanel` does not change the frontmost application, there is a subtle window where `NSWorkspace` may update its internal state during panel appearance.
- If `capturePreviousApp()` is called *after* the panel appears, the returned frontmost application might, under some OS versions or race conditions, already reflect Flourish rather than the previous app.

---

## Context — the race condition

The issue was discovered during development when occasionally the paste would land in Flourish's own main window rather than the target app. Investigation showed that on some macOS 13.x versions, `NSWorkspace.shared.frontmostApplication` could briefly return the newly-appeared panel's owner (even for non-activating panels) due to window server notification timing.

---

## Decision Rationale

The fix is simple and has zero cost: call `capturePreviousApp()` as the *first* operation in `show()`, before anything else:

```swift
func show() {
    PasteService.shared.capturePreviousApp()    // ← FIRST
    overlayViewModel.reset()
    panel.center()
    panel.makeKeyAndOrderFront(nil)
    installEscapeMonitor()
}
```

By capturing before the panel appears, we guarantee that `NSWorkspace.shared.frontmostApplication` returns the app the user was in.

---

## Alternatives Considered

### Capture after the panel appears
Simpler ordering, but subject to the race condition described. Rejected.

### Capture in the hotkey handler, before `toggle()` is called
Would work, but adds coupling between `AppDelegate` and `PasteService`. The current approach keeps the capture inside `OverlayWindowController.show()`, which is where it logically belongs. Rejected.

### Use an accessibility API to find the focused element's owner
More robust but significantly more complex. Overkill when the simple timing fix works reliably. Rejected.

---

## Consequences

- Paste always targets the correct previous app. ✓
- The ordering is documented here and in comments in `OverlayWindowController.show()`. ✓
- Any future refactoring of `show()` must preserve this ordering. (This ADR serves as the warning.)

---

## Related

- [Paste Automation Explanation](../explanation/paste-automation.md)
- [Overlay Focus Model Explanation](../explanation/overlay-focus-model.md)
- [ADR-001: Non-Activating Panel](001-non-activating-panel.md)
