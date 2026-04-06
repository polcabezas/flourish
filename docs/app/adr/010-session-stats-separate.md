# ADR-010: Session Stats Separate from Persisted Stats

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Maintain two separate statistics systems: a session-only `SessionStatsTracker` (in-memory, resets on launch) and persistent all-time stats via `Defaults` keys. Display both on the Home screen.

---

## Context

The Home screen's header area shows statistics about Flourish usage. Two types of stats are useful:
- **Session stats**: how many improvements were made in the current launch. Useful for seeing "what I did today."
- **All-time stats**: cumulative totals since first use. Useful for understanding overall usage and cost.

These have different storage requirements:
- Session stats are ephemeral by definition. They should reset on every app launch.
- All-time stats must survive restarts.

---

## Alternatives Considered

### Single stats system (persisted only)
Store only all-time stats in UserDefaults. Display them everywhere. Session stats would require calculating a "start-of-session baseline" by snapshotting values at launch and computing differences. Adds complexity and is error-prone (what if the app crashes mid-session?). Rejected.

### Single stats system (derived from history)
Calculate all stats by querying the SQLite history table. `SELECT COUNT(*), SUM(tokens_in), SUM(tokens_out), SUM(estimated_cost_usd) FROM history_entry`. Accurate, but requires a database query every time the Home screen renders. For session stats (last N entries since launch), requires knowing the launch time and filtering by `created_at`. Adds database read latency to the home screen load. Rejected in favor of cached approach.

---

## Decision Rationale

`SessionStatsTracker` is a `@Published ObservableObject` singleton that accumulates session data in-memory:

```swift
final class SessionStatsTracker: ObservableObject {
    static let shared = SessionStatsTracker()
    @Published var requestCount: Int = 0
    @Published var tokensIn: Int = 0
    @Published var tokensOut: Int = 0
    @Published var costUSD: Double = 0.0
    
    func record(_ response: LLMResponse, cost: Double) {
        requestCount += 1
        tokensIn += response.tokensIn
        tokensOut += response.tokensOut
        costUSD += cost
    }
}
```

After each successful LLM call, `OverlayWindowController` calls both:
1. `SessionStatsTracker.shared.record(response, cost: cost)` — updates in-memory session stats
2. `Defaults[.totalRequestCount] += 1` etc. — updates persisted all-time stats

SwiftUI views observe `SessionStatsTracker.shared` via `@ObservedObject` and `Defaults[.*]` via `@Default`. Both update automatically.

---

## Consequences

- Session stats reset on every launch — always reflects "this session." ✓
- All-time stats persist across launches — accurate cumulative totals. ✓
- No UserDefaults writes on every LLM call for session stats (only all-time stats are written). ✓
- Zero database queries for stats display. ✓
- If the app crashes mid-session, all-time stats may be partially written (race between Defaults writes). Acceptable — stats are informational, not transactional.

---

## Related

- [App Settings Reference](../reference/app-settings.md) — `totalRequestCount`, `totalTokensIn`, `totalTokensOut`, `totalCostUSD` keys
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
