# ADR-037: Loader success state, AX-based paste detection, and fixed-frame NSHostingView

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Three related changes were made to the loader and paste pipeline as a single coherent unit:

1. **`LoaderState` grows a `.success` phase.** After the LLM responds, `LoaderWindowController.showSuccess(pasted:)` transitions the pill from a spinner to a checkmark + contextual message ("Pasted" or "Copied to clipboard"), then auto-hides after 1.5 s.

2. **`PasteService.pasteText()` returns `Bool` and uses `AXFocusedUIElement` to gate Cmd+V.** Before firing the paste event, the service checks that the previous app has a focused text input (`AXTextField`, `AXTextArea`, `AXComboBox`, `AXSearchField`, or editable `AXWebArea`). If not, it skips Cmd+V entirely (no error sound) and returns `false`. `OverlayWindowController.runLLM` passes the return value to `showSuccess(pasted:)` to pick the correct message.

3. **Clipboard restore is removed.** The improved text is left in the clipboard unconditionally, whether paste succeeded or not.

4. **`LoaderState.width: CGFloat` is published and the SwiftUI view is always `frame(width: state.width, height: FS.loaderHeight)`.** `LoaderWindowController` measures the success message at runtime with `NSFont.systemFont(ofSize: 11)` and sets both the `LoaderState.width` and the `NSWindow` frame before the phase transition, so `NSHostingView` always sees a stable preferred content size.

5. **The loader uses `panel.contentView = NSHostingView(rootView:)` instead of `contentViewController`.** This breaks the `NSHostingView.updateAnimatedWindowSize` feedback loop that crashed the app when the pill resized.

---

## Context

### Paste detection gap

Previously, `PasteService` fired Cmd+V unconditionally after activating the previous app. If the cursor was not in a text field (e.g. the user had clicked a toolbar button before triggering the shortcut), macOS would play the system error sound. This was confusing — the improved text was in the clipboard but users heard a failure signal with no explanation.

Because the overlay is a `nonactivatingPanel`, the previous app never loses focus and its `AXFocusedUIElement` attribute remains valid throughout the overlay interaction. This makes it safe and cheap to query before firing the paste.

### Clipboard restore was harmful

The original implementation saved the clipboard contents before writing the improved text and restored them after the paste. This created a narrow race: if the user dismissed the overlay and immediately pressed Cmd+V in another app before the async restore ran, they would paste the original clipboard contents instead of the improved text. Removing the restore eliminates the race and gives users a reliable fallback — the improved text is always available for a manual Cmd+V.

### NSHostingView layout loop

When the loader pill needed to widen for the success message, changing the `NSWindow` frame caused AppKit to call `NSHostingView.updateAnimatedWindowSize`, which asked SwiftUI for a new preferred size, which changed the frame again — an infinite loop. Two fixes together break the cycle:

- **Fixed frame on the SwiftUI side**: `LoaderView` always reports `state.width × FS.loaderHeight`, so the preferred content size is constant relative to the current window frame.
- **`contentView` instead of `contentViewController`**: `NSHostingController` as `contentViewController` participates in AppKit's constraint-update cycle more aggressively. Assigning an `NSHostingView` directly to `contentView` sidesteps the cycle entirely.

---

## Alternatives Considered

### A. Keep clipboard restore, skip paste if no focused input

Rejected: removing restore is independently correct (eliminates the race). The two concerns should not be coupled.

### B. Use `kAXEditedAttribute` on all roles to detect text inputs

Rejected: `AXTextField` and `AXTextArea` do not always set `kAXEditedAttribute` to `true` even when writable. Checking the role directly is more reliable; `kAXEditedAttribute` is only consulted for the ambiguous `AXWebArea` case.

### C. Animate the pill width with `NSAnimatablePropertyContainer`

Rejected: the pill auto-hides after 1.5 s. A width animation would complete after hide. The instantaneous resize before the phase transition is imperceptible in practice.

### D. `NSHostingController` as `contentViewController` with explicit size constraints

Rejected: the workaround requires setting `preferredContentSize` manually and fighting AppKit's constraint system. Switching to `contentView` is simpler and has no downsides for this use case.

---

## Consequences

- **`PasteService.swift`:** `pasteText(_:)` is `@discardableResult` → `Bool`. `hasFocusedTextInput(in:)` is a new private method using `AXFocusedUIElement` + `AXRole`. `restoreClipboard()` and its associated saved-clipboard state are deleted.
- **`LoaderView.swift`:** `LoaderState` gains `phase: Phase` (`.loading` / `.success`), `successMessage: String`, and `width: CGFloat`. `LoaderView` renders a `ProgressView()` spinner (`.tint(.flourishAccent)`) for `.loading` and a checkmark + text for `.success`. Both phases share the same pill shell with `frame(width: state.width, height: FS.loaderHeight)`.
- **`LoaderWindowController.swift`:** `show()` resets to `.loading` / `FS.loaderWidth`. `showSuccess(pasted:)` computes the success width from `NSFont.systemFont(ofSize: 11)`, sets `loaderState.width`, `loaderState.successMessage`, and `loaderState.phase` together, then calls `applyFrame(width:)`. `hide()` is called automatically after 1.5 s via a `Task.sleep`. The panel uses `contentView = NSHostingView(rootView:)`.
- **`OverlayWindowController.swift`:** `runLLM` calls `let pasted = PasteService.shared.pasteText(response.improvedText)` and passes it to `LoaderWindowController.shared.showSuccess(pasted: pasted)`.
- **Design system:** `FS.loaderWidth` (80 pt) remains the default loading-phase width. No new tokens.

---

## Related

- [ADR-011: Capture previous app before showing overlay](011-paste-capture-timing.md)
- [ADR-017: NSHostingController for the overlay panel](017-nshosting-controller-for-overlay.md)
- [ADR-001: Non-activating NSPanel for the overlay](001-non-activating-panel.md)
