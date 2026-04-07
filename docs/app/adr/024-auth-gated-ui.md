# ADR-024: Auth-gated UI — sign-in panel shown on launch and sign-out

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

All app functionality is gated behind authentication. On launch, if no authenticated session exists, `SignInWindowController` shows immediately and the main window is blocked. When the user signs out, the main window is hidden and the sign-in panel is shown again. Accessibility permission is requested only after the user has successfully signed in.

---

## Context

With the introduction of user accounts and per-user billing limits, allowing unauthenticated access to the core prompt improvement flow is no longer possible. The Worker validates JWTs derived from the Supabase session; an unauthenticated user has no valid token and cannot make requests.

The design question was: where and how to enforce this gate in the macOS AppKit/SwiftUI UI, given flourish's existing architecture of singleton window controllers and a non-activating overlay panel.

---

## Alternatives Considered

### A. Block at the overlay level only

Rejected. If the user is not signed in, pressing Ctrl+Space would open the overlay, the user would type a prompt, press Return, and then receive an error. This is a poor experience — the error comes at the last moment, after the user has already done work.

### B. Show an inline "sign in" state inside the main window

Considered. The main window could show a "please sign in" placeholder instead of Home/Profiles/Settings content. Rejected because:
- The overlay is still reachable via the global hotkey — blocking only the main window leaves the hotkey path open
- A dedicated `SignInWindowController` is a cleaner separation: auth lives in its own panel, not inside the main window's navigation

### C. Dedicated SignInWindowController, shown on launch/sign-out (chosen)

`AppDelegate.applicationDidFinishLaunching` calls `AuthService.shared.startObservingAuthState()`. The stream's first emission determines the initial UI state:
- If no session: `SignInWindowController.shared.show()`
- If session exists: proceed to normal app startup

`MenuBarManager.openMainWindow()` and `openSettings()` check authentication before acting. If not authenticated, they call `SignInWindowController.shared.show()` instead. This closes the hotkey path: the overlay can only be reached when the user is logged in because the global hotkey handler in `AppDelegate` also checks auth state.

---

## Accessibility Permission Deferral

In the previous architecture, `AppDelegate.applicationDidFinishLaunching` requested Accessibility permission immediately on launch via `AXIsProcessTrusted()`.

With auth gating, requesting Accessibility permission before the user has signed in is premature: the dialog may confuse users who do not yet understand what the app does. The request is now deferred to after the first successful sign-in.

The `AuthService.authStateChanges` stream is observed in `AppDelegate`. On the first emission of a signed-in event, `ensureAccessibilityPermission()` is called. Subsequent signed-in events (e.g., token refresh) do not repeat the request because `AXIsProcessTrusted()` returns `true` after the first grant.

---

## SignInWindowController Design

`SignInWindowController` is a `@MainActor NSWindowController` singleton (`static let shared`). It owns a private `NSPanel` (320pt wide, compact height) and hosts `SignInView` as its content view controller.

`SignInView` is a SwiftUI view providing:
- The flourish logo
- Email and password `TextField`/`SecureField` inputs
- Sign In / Sign Up toggle
- Google OAuth button (uses `GoogleLogo` image asset)

The panel is centered on screen via `window?.center()` in `show()` and dismissed via `orderOut(_:)` in `hide()`.

`AuthService` drives the transition: when `authStateChanges` emits `.signedIn`, `SignInWindowController.shared.hide()` is called and the main window becomes available. When `.signedOut` is emitted, the main window is closed and `SignInWindowController.shared.show()` is called.

---

## Consequences

- Cold launch always observes auth state before showing any app UI. There is a brief moment before the stream emits its first value — no UI is shown during this window (the status bar icon appears, but no window).
- The global hotkey (Ctrl+Space) is still registered on launch regardless of auth state. The handler checks `AuthService.shared` at call time. If not authenticated, the hotkey is a no-op and shows the sign-in panel instead.
- Accessibility permission is no longer requested for users who never complete sign-in (e.g., those who quit during onboarding). This is a privacy improvement.
- `SignInWindowController` must remain alive for the application lifetime. It is a singleton.

---

## Related

- [ADR-007: Singleton Window Controllers](007-singleton-window-controllers.md)
- [ADR-023: Supabase Auth Strategy](023-supabase-auth-strategy.md)
- [Architecture Overview](../reference/architecture-overview.md)
