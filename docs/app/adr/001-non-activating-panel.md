# ADR-001: Non-Activating NSPanel for the Overlay

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use `NSPanel` with the `.nonactivatingPanel` style mask for the flourish overlay, rather than a standard `NSWindow`.

---

## Context

flourish's core value proposition is improving prompts without breaking the user's workflow. The user should be able to:
1. Press a hotkey while in any app.
2. Type in the overlay.
3. Have the improved text paste back into the original app.

For step 3 to work, the original app must still be "active" (frontmost) from the perspective of macOS's `NSPasteboard` paste target and `CGEvent` routing. If opening the overlay switches the active application to flourish, then pasting would land in flourish rather than in the original app.

macOS's `NSWindow` always activates the owning application when brought to front. `NSPanel` with `.nonactivatingPanel` can receive keyboard input without changing the frontmost application.

---

## Alternatives Considered

### Standard NSWindow
Opening a standard window would activate flourish and deactivate the previous app. The paste step would fail. Rejected.

### Accessibility-based input capture
Intercept keystrokes at the OS level without showing a window. Too complex to implement reliably across all apps; no text input affordance. Rejected.

### Menu bar popover (NSPopover from NSStatusItem)
Menu bar popovers are non-activating by nature. However, they are constrained in size, positioned near the menu bar (awkward for a typing surface), and have limited focus/keyboard event semantics. Rejected.

---

## Consequences

- The overlay receives keyboard input without changing the frontmost app. ✓
- `PasteService.capturePreviousApp()` works correctly because the frontmost app never changes during the overlay session. ✓
- The overlay does not appear in Cmd+Tab or Mission Control (NSPanel behavior). Acceptable UX trade-off.
- Setting `level = .floating` is required to ensure the panel appears above normal windows of the active app. ✓
- Accessibility permission is required for `CGEvent` paste simulation (this is independent of the panel choice). ✓

---

## Related

- [Overlay Focus Model](../explanation/overlay-focus-model.md)
- [Paste Automation](../explanation/paste-automation.md)
- [ADR-011: Paste Capture Timing](011-paste-capture-timing.md)
