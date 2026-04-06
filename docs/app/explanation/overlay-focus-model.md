# Overlay Focus Model

Why the Flourish overlay uses a non-activating `NSPanel`, and what this means for the user experience and implementation.

---

## The core constraint

The overlay's entire value proposition depends on a single behavioral requirement: **opening the overlay must not switch keyboard focus away from the user's current app**.

Consider the workflow:
1. User is typing a prompt in ChatGPT's web interface.
2. User presses Ctrl+Space to invoke Flourish.
3. User types a refined version of the prompt in the overlay.
4. User presses Return.
5. The improved text is pasted into ChatGPT.

If step 2 caused macOS to switch the active application to Flourish, step 5 would paste into Flourish (or nowhere useful) rather than into ChatGPT. The entire workflow breaks.

---

## Why NSPanel with non-activating style

macOS's `NSPanel` class, unlike `NSWindow`, supports the `.nonactivatingPanel` style mask. A panel with this mask:

- **Can become key** (receive keyboard events) when explicitly told to via `makeKeyAndOrderFront(_:)`
- **Does not change the frontmost application** when it becomes key
- **Does not appear in the Cmd+Tab application switcher**

This is precisely the behavior Flourish needs. The overlay receives keyboard input (so the user can type) while the "frontmost app" from macOS's perspective remains whatever it was before the hotkey was pressed.

```swift
class OverlayPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        level = .floating
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = false
    }
}
```

---

## Focus timeline

```
t=0  User is in App A (e.g., browser), browser is frontmost app
t=1  User presses Ctrl+Space
t=2  PasteService.capturePreviousApp()  ← NSWorkspace.shared.frontmostApplication
         saves reference to App A BEFORE the panel appears
t=3  OverlayPanel.makeKeyAndOrderFront(nil)
         panel is now key window (receives keyboard input)
         App A is STILL the frontmost application
t=4  User types in the overlay (keyboard events go to OverlayPanel)
t=5  User presses Return
t=6  Panel hides
t=7  PasteService reactivates App A explicitly:
         NSWorkspace.shared.frontmostApplication? is still App A (never changed)
         We call previousApp.activate(options: [])
t=8  CGEvent Cmd+V is posted
         App A receives the Cmd+V because it is now frontmost and key
```

---

## Why capture the previous app BEFORE showing the panel

`PasteService.capturePreviousApp()` is called before `OverlayPanel.makeKeyAndOrderFront(_:)`. This ordering is critical.

Even though a non-activating panel doesn't change the frontmost app, there is a subtle race condition: if we queried `NSWorkspace.shared.frontmostApplication` *after* the panel is shown, macOS may have already updated its internal "previously active app" state. By capturing the reference first, we guarantee we have the correct app to reactivate after the LLM call completes.

See [ADR-011: Paste Capture Timing](../adr/011-paste-capture-timing.md).

---

## Dynamic panel sizing with NSHostingController

The overlay panel resizes vertically as the user types. `OverlayView` uses a `TextEditor` with `frame(minHeight: FS.overlayInputMinHeight, maxHeight: 320)`: the editor (and therefore the panel) expands up to 320 pt as content grows, after which the editor scrolls internally.

Getting this to work correctly in an AppKit panel requires using `NSHostingController` as the `contentViewController`, not an `NSHostingView` pinned to the content view with four Auto Layout constraints.

### Why NSHostingView + constraints fails

Pinning an `NSHostingView` to all four edges of `panel.contentView` with Auto Layout constraints locks the window to its initial size. Auto Layout resolves the SwiftUI view's dimensions to fill the fixed container rather than letting SwiftUI drive the container's size. The window never resizes in response to text changes.

### How NSHostingController solves it

Setting `NSHostingController` as `panel.contentViewController` and enabling `sizingOptions = .preferredContentSize` (macOS 13+) instructs AppKit to continuously propagate the SwiftUI hierarchy's preferred content size into `NSPanel.contentSize`. No manual resize code is needed; the panel grows and shrinks automatically as the SwiftUI layout changes.

```swift
let hostingController = NSHostingController(rootView: OverlayView(viewModel: overlayViewModel))
hostingController.sizingOptions = .preferredContentSize
panel.contentViewController = hostingController
```

First-open centering uses `hostingController.sizeThatFits(in:)` to obtain the correct initial height before positioning the panel, rather than relying on an arbitrary initial size.

See [ADR-017: NSHostingController over NSHostingView for the overlay panel](../adr/017-nshosting-controller-for-overlay.md).

---

## Window level: floating

The panel's `level` is set to `.floating`. This ensures the overlay appears above the content of normal application windows (including full-screen apps on the same Space). Without this, the overlay could appear behind the very app the user is working in.

---

## Accessibility permission and CGEvent

The paste-back mechanism uses `CGEvent` to post a synthetic Cmd+V keystroke. This requires the **Accessibility permission** (`AXIsProcessTrusted`). Without it, `CGEvent` posting is silently blocked.

Flourish requests this permission proactively at launch via `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`. If permission is denied and the user tries to improve a prompt, the app shows an NSAlert explaining how to grant it in System Settings → Privacy & Security → Accessibility.

---

## Trade-offs

| Benefit | Cost |
|---------|------|
| Workflow is seamless — user never leaves their app | Requires Accessibility permission |
| Works with any app (browsers, terminals, native apps) | Accessibility permission UI is unfamiliar to some users |
| Non-activating panel is a standard macOS pattern | Panel doesn't appear in Mission Control or Exposé |

---

## Related

- [ADR-001: Non-Activating Panel](../adr/001-non-activating-panel.md)
- [ADR-017: NSHostingController over NSHostingView for the overlay panel](../adr/017-nshosting-controller-for-overlay.md)
- [Paste Automation Explanation](paste-automation.md)
- [Prompt Improvement Workflow](prompt-improvement-workflow.md)
- [Platform Security: Accessibility](../../platform/security.md)
