# ADR-031: Event-Driven Usage Refresh in AccountViewModel

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

`AccountViewModel` subscribes to two `NotificationCenter` events — `.flourishDidImprovePrompt` (posted after each successful LLM response) and `NSApplication.didBecomeActiveNotification` (posted when the user brings the app to the foreground) — and calls `loadUsage()` on both. `OverlayWindowController` posts `.flourishDidImprovePrompt` immediately after receiving the improved text, before updating local stats.

---

## Context

`AccountView` displays a usage bar showing requests consumed against the monthly plan limit (e.g. "47 / 2 000"). The data comes from a `GET /usage` call to the Cloudflare Worker, which queries Supabase for the current `requests_this_month` value.

Prior to this change, `AccountViewModel.loadUsage()` was called only once — when `AccountView` first appeared. This meant:

1. **Counter lag after improvements**: a user who ran a prompt while `AccountView` was open would see the bar frozen at the stale count until they navigated away and back.
2. **Plan changes not reflected**: when a Stripe webhook updated the user's plan in Supabase, the new limit was not visible until the app was relaunched.

Neither scenario caused data loss, but both created confusion: the usage bar appeared broken.

---

## Alternatives Considered

### Polling on a timer
Schedule a `Timer` every N seconds while `AccountView` is visible. Guarantees freshness regardless of trigger source. Rejected — wasteful; the Worker performs a database read on every request, and usage data only changes on two concrete events (a successful improvement or a Stripe webhook). Polling adds background network traffic for no benefit.

### Observable / reactive store
Expose `requests_this_month` as a `@Published` property on a shared `UsageStore` singleton. `OverlayWindowController` increments it locally after each improvement without a network round-trip. Rejected — local increment diverges from the server if the Worker rejects the request (quota exceeded, auth error, etc.), and plan-limit changes from Stripe webhooks would still require a separate signal. A full reactive store would need a server reconciliation mechanism anyway.

### Refresh on `AccountView.onAppear`
Call `loadUsage()` every time the view appears (i.e. the user navigates to the Account tab). Simple, but misses in-session improvements while the view stays open and misses plan changes triggered externally. Retained as a fallback — `onAppear` still triggers `loadUsage()` for the initial load; the notification subscriptions complement it.

---

## Decision Rationale

Two targeted subscriptions cover the realistic update scenarios at minimal cost.

### Notification name

A canonical name is defined as an extension on `Notification.Name` to avoid stringly-typed usage:

```swift
extension Notification.Name {
    static let flourishDidImprovePrompt = Notification.Name("flourishDidImprovePrompt")
}
```

### Posting the notification

`OverlayWindowController` posts the notification immediately after receiving the improved text from `FlourishProxyService`, before updating `SessionStatsTracker` or `Defaults`:

```swift
let improved = try await FlourishProxyService.shared.improvePrompt(...)
NotificationCenter.default.post(name: .flourishDidImprovePrompt, object: nil)
// local stats updates follow...
```

Posting before local stats ensures that when `AccountViewModel.loadUsage()` fires, the Worker's counter has already been incremented (the POST to `/improve` has returned successfully).

### Subscribing in AccountViewModel

`AccountViewModel.init()` sets up both subscriptions using Combine and stores the cancellables for the lifetime of the instance:

```swift
import Combine

final class AccountViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: .flourishDidImprovePrompt)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUsage() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUsage() }
            .store(in: &cancellables)
    }
}
```

`receive(on: DispatchQueue.main)` ensures `loadUsage()` — which publishes `@Published` properties — always runs on the main actor.

---

## Consequences

- The usage bar updates within seconds after each successful improvement, while `AccountView` is open. ✓
- Plan changes applied via Stripe webhook are picked up the next time the user focuses the Flourish window. ✓
- No background polling — network calls happen only on meaningful events. ✓
- Subscriptions live for the lifetime of the `AccountViewModel` instance, which matches the lifetime of `AccountView`. When the view is dismissed, the view model is released and subscriptions are cancelled automatically. ✓
- Each improvement triggers one extra `GET /usage` call to the Worker. At typical usage volumes this is negligible; if usage tracking costs become a concern a short debounce can be added to the sink without changing the overall pattern.
- `NSApplication.didBecomeActiveNotification` fires on every app focus event (not just Account tab focus), so `loadUsage()` may be called when the user is on a different tab. The call is cheap and the result is discarded if `AccountView` is not visible; this is acceptable.

---

## Related

- [ADR-025: Cloudflare D1 Usage Tracking](025-cloudflare-d1-usage-tracking.md) — superseded but explains the original usage tracking design
- [ADR-027: Supabase PostgreSQL over D1](027-supabase-postgres-over-d1.md) — current persistence layer for `requests_this_month`
- [ADR-010: Session Stats Separate from Persisted Stats](010-session-stats-separate.md) — parallel pattern for local session stats
- [ADR-026: Stripe Billing via Worker](026-stripe-billing-via-worker.md) — Stripe webhooks are why app-focus refresh is needed
