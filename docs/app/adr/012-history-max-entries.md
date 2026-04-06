# ADR-012: Maximum 500 History Entries

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Cap the SQLite history table at 500 entries. When a new entry is inserted and the count exceeds 500, the oldest entries (by `created_at`) are automatically deleted.

---

## Context

Without a capacity limit, the history database grows indefinitely. Users who use Flourish heavily for months or years could accumulate thousands of entries. The implications:
- Larger database file on disk (minor, since prompts are small).
- Slower queries on unindexed columns (mitigated by the `created_at` index).
- More data to scroll through in the Home view without a clear value proposition.

The history feature's primary use case is **recent context** — browsing prompts from the past few sessions. Long-tail history (e.g., from 6 months ago) has limited utility without a more sophisticated search/organization UI.

---

## Alternatives Considered

### No limit (unlimited history)
Simple to implement. Acceptable performance for most users. But adds unbounded disk usage and UI clutter. Rejected.

### Time-based limit (e.g., keep last 30 days)
More intuitive to users. Harder to implement (requires a scheduled cleanup job or cleanup on every launch). The correct cutoff date is hard to decide. Rejected in favor of a count-based limit.

### User-configurable limit
Adds settings UI complexity for a low-value setting. Defaults to 500, which is sufficient for all current use cases. Rejected.

### Smaller limit (e.g., 100 entries)
Would be too restrictive for users who use Flourish daily. 500 entries at ~500 bytes each = ~250KB maximum database size. Negligible. Rejected.

---

## Decision Rationale

500 entries is large enough for meaningful history browsing and small enough that the `fetchAll` query (sorted by `created_at DESC`) is fast even without a full-text index.

Enforcement on insert:
```swift
func insert(_ entry: HistoryEntry) throws {
    try dbQueue.write { db in
        var e = entry
        try e.insert(db)
        let count = try HistoryEntry.fetchCount(db)
        if count > maxEntries {
            let excess = count - maxEntries
            try HistoryEntry
                .order(Column("created_at").asc)
                .limit(excess)
                .deleteAll(db)
        }
    }
}
```

The insert and trim happen in a single transaction, preventing temporary over-capacity states.

---

## Consequences

- Database size is bounded at ~250KB in the worst case. ✓
- Oldest entries are automatically evicted without user action. ✓
- The `created_at` index makes the `ORDER BY created_at ASC LIMIT N` deletion query fast. ✓
- Users with heavy usage may lose history older than their most recent 500 entries — acceptable given the use case.
- No export or archive mechanism in v1.0.0. Future enhancement opportunity.

---

## Related

- [Database Schema Reference](../reference/database-schema.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [ADR-003: GRDB over CoreData](003-grdb-over-coredata.md)
