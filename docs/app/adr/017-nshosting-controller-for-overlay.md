# ADR-017: NSHostingController over NSHostingView for the overlay panel

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Embed the `OverlayView` SwiftUI hierarchy into `OverlayPanel` via `NSHostingController` set as `panel.contentViewController`, with `hostingController.sizingOptions = .preferredContentSize`. Replace the previous approach of an `NSHostingView` pinned to the panel's content view with four Auto Layout constraints.

---

## Context

The flourish overlay must resize dynamically as the user types. The `TextEditor` inside `OverlayView` is configured with a `frame(minHeight:maxHeight:)` modifier: it starts at `overlayInputMinHeight` and expands up to 320 pt as content grows, after which the editor scrolls internally. For this to work, the `NSPanel` itself must grow and shrink in response to the SwiftUI view's preferred content size.

Under the previous `NSHostingView` + 4-edge constraint approach:

1. An `NSHostingView` was added to `panel.contentView`.
2. Leading, trailing, top, and bottom constraints pinned the hosting view to all four edges of the content view.
3. This locked the panel to its initial size. The constraint system prevented the panel from ever changing height: Auto Layout resolved the SwiftUI view's size to fit the fixed content view, rather than letting the SwiftUI view drive the panel size.
4. The panel was centered before the first layout pass using `panel.center()`, which positioned the window based on whatever arbitrary size it happened to have at that moment, not the correct rendered size.

The result was an overlay whose height did not reflect the text content, a first-open centering that was often off by tens of points, and a TextEditor that could never expand.

---

## Alternatives Considered

### A. NSHostingView + 4-edge constraints (previous approach)

Described above. The window remains at its initial size regardless of SwiftUI content changes. Rejected.

### B. NSHostingView + `invalidateIntrinsicContentSize` + manual resize

Override `NSHostingView.intrinsicContentSize` and call `panel.setContentSize(_:)` manually in a `onChange` or `PreferenceKey` callback. This can work but requires a bespoke synchronisation loop, is brittle across macOS versions, and reimplements behavior that `NSHostingController` provides natively. Rejected.

### C. NSHostingController with sizingOptions = .preferredContentSize (chosen)

`NSHostingController` is the AppKit-native container for a SwiftUI root view. Setting `sizingOptions = .preferredContentSize` (available since macOS 13) tells the controller to continuously propagate SwiftUI's preferred content size into the parent `NSWindow`/`NSPanel` via `preferredContentSize`. When set as `contentViewController`, AppKit automatically resizes the window to match. No manual resize code is required.

The first-open size is obtained by calling `hostingController.sizeThatFits(in: largeSize)` before centering, which forces an initial layout pass and returns the correct initial height. The panel is then centered using the actual rendered dimensions.

---

## Consequences

- The `OverlayPanel` grows from `overlayInputMinHeight` up to 320 pt as the user types, then holds at 320 pt while the `TextEditor` scrolls internally. ✓
- First-open centering is computed from the actual SwiftUI layout size, not an approximation. ✓
- No manual `setContentSize` or `invalidateIntrinsicContentSize` calls anywhere in the controller. ✓
- `sizingOptions = .preferredContentSize` requires macOS 13+. flourish already targets macOS 13+ so this is not a new constraint. ✓
- The `NSHostingView` + constraint code is removed entirely. The `OverlayWindowController` `init` is simpler. ✓
- SwiftUI scroll indicators on the `TextEditor` are hidden (`.scrollIndicators(.hidden)`) to avoid visual noise during resize. ✓

---

## Implementation Notes

```swift
// In OverlayWindowController.init()
let hostingController = NSHostingController(rootView: OverlayView(viewModel: overlayViewModel))
hostingController.sizingOptions = .preferredContentSize
panel.contentViewController = hostingController

// In centerOnScreen()
let screen = NSScreen.main ?? NSScreen.screens[0]
let screenFrame = screen.visibleFrame
let fitsSize = hostingController.sizeThatFits(in: CGSize(
    width: panel.frame.width,
    height: CGFloat.greatestFiniteMagnitude
))
let panelHeight = fitsSize.height
let x = screenFrame.midX - panel.frame.width / 2
let y = screenFrame.midY - panelHeight / 2 + screenFrame.height * 0.08
panel.setFrameOrigin(CGPoint(x: x, y: y))
```

The `0.08 * screenFrame.height` offset positions the panel slightly above the true screen center, matching the visual convention for tool palettes and command palettes on macOS.

---

## Related

- [ADR-001: Non-Activating NSPanel for the Overlay](001-non-activating-panel.md)
- [Overlay Focus Model](../explanation/overlay-focus-model.md)
- [Architecture Overview](../reference/architecture-overview.md)
