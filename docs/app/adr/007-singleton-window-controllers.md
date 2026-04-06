# ADR-007: Singleton Pattern for Window Controllers

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Implement `OverlayWindowController`, `LoaderWindowController`, `MainWindowController`, `MenuBarManager`, `HistoryStore`, `KeychainService`, `PasteService`, and `SessionStatsTracker` as singletons via a `static let shared = Self()` pattern.

---

## Context

In AppKit, each `NSWindow` or `NSPanel` represents a single on-screen resource. Creating multiple instances of a window controller for the same window leads to:
- Multiple panels appearing at the same time.
- Race conditions in show/hide state.
- Inconsistent state between the controller that showed the window and the one trying to hide it.

The overlay workflow requires tight coordination across:
- `AppDelegate` (hotkey fires → calls `OverlayWindowController.shared.toggle()`)
- `OverlayWindowController` (orchestrates the full LLM flow)
- `LoaderWindowController` (shown/hidden by `OverlayWindowController`)
- `PasteService` (used by `OverlayWindowController`)
- `HistoryStore` (written by `OverlayWindowController`, read by `HomeView`)

Each of these must refer to the same instance.

---

## Alternatives Considered

### Dependency injection via environment objects
Inject singletons into the SwiftUI environment using `@EnvironmentObject`. Works for views, but AppKit delegates and window controllers are not in the SwiftUI environment tree. Would require passing instances through multiple layers of mixed AppKit/SwiftUI code. Rejected.

### Passed as constructor parameters
Explicit dependency injection at every call site. Adds boilerplate without benefit when there is only ever one instance of each. Rejected for AppKit-facing code.

### Factory / service locator
A central registry for all services. Adds indirection and complexity; not idiomatic Swift. Rejected.

---

## Decision Rationale

Singletons are the standard pattern for AppKit resources that must exist exactly once per process. Every major macOS app (and Apple's own sample code) uses singleton window controllers. The pattern is:

```swift
final class OverlayWindowController: NSWindowController {
    static let shared = OverlayWindowController()
    private init() {
        let panel = OverlayPanel()
        super.init(window: panel)
        // setup...
    }
    required init?(coder: NSCoder) { fatalError() }
}
```

Private `init()` prevents accidental second instantiation. `static let` is thread-safe in Swift by specification.

---

## Consequences

- There is always exactly one overlay, one loader, one main window, one menu bar item. ✓
- Any code in any file can safely call `OverlayWindowController.shared.toggle()`. ✓
- No dependency injection framework needed for the AppKit layer. ✓
- Unit testing singleton-based code requires method injection or subclassing — not ideal, but acceptable for UI-layer controllers where integration testing is more valuable anyway.
- Singletons must be careful about initialization order. All `shared` instances are lazily initialized (Swift's `static let` guarantees this). ✓

---

## Related

- [Architecture Overview](../reference/architecture-overview.md) — Singleton Pattern section
