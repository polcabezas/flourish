# ADR-003: GRDB.swift over CoreData for History Storage

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use GRDB.swift (a Swift SQLite ORM) for the prompt history store instead of CoreData.

---

## Context

Flourish needs to persist a history of prompt-improvement events with:
- A fixed schema (9 columns, no relationships).
- Full-text search on two text columns.
- Chronological sorting with range filtering.
- A simple capacity limit (delete oldest when over 500).
- Read access from the main thread (history list view) and write access from async tasks.

Two options were considered: CoreData (Apple's ORM) and GRDB (a community SQLite wrapper).

---

## Alternatives Considered

### CoreData
CoreData is Apple's full-featured object graph persistence framework:
- Requires a managed object context, persistent store coordinator, and NSManagedObject subclasses.
- Threading model requires careful context management (separate contexts per thread, or a view context + background context).
- Supports relationships, faulting, and change tracking — all unnecessary for a single flat table.
- Debugging requires Core Data visualizer tools or NSFetchRequest inspection.
- Migration requires a versioned model file and explicit migration policies.

For a single-table schema with no relationships, CoreData's overhead was deemed disproportionate.

### SwiftData
Apple's newer macro-based ORM built on CoreData. Still under active development at the time of this decision. Has the same underlying complexity as CoreData for custom migrations and direct SQL access. Avoided for stability reasons.

### Raw SQLite (sqlite3 C API)
Maximum control and zero overhead, but requires manual binding, row decoding, and error handling for every query. Development speed is significantly slower. Rejected.

---

## Decision Rationale

GRDB provides:
- Type-safe row decoding via `FetchableRecord` / `MutablePersistableRecord`.
- Direct SQL for queries where the ORM abstraction is insufficient.
- A simple, explicit migration system (`DatabaseMigrator`).
- `DatabaseQueue` with automatic thread safety (serialized writes, concurrent reads).
- Zero "magic" — every operation maps to an obvious SQL statement.

The schema is simple enough that CoreData's additional capability (graph persistence, lazy faulting, change notifications) provides no benefit.

---

## Consequences

- History is stored at `~/.local/share/com.personal.flourish/history.db`. ✓
- Schema migrations are code-only (`DatabaseMigrator` in `HistoryStore.swift`). ✓
- SQL queries are readable and debuggable (open the database with any SQLite client). ✓
- No NSManagedObjectContext threading concerns. ✓
- GRDB.swift is an SPM dependency — if the package is discontinued, migration to raw SQLite is straightforward. Risk: low.
- No built-in iCloud sync (acceptable — history is device-local by design). ✓

---

## Related

- [Database Schema Reference](../reference/database-schema.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [ADR-012: Max 500 History Entries](012-history-max-entries.md)
