# Database Schema Reference

The SQLite database used by Flourish for prompt history storage, managed via the GRDB Swift package.

---

## Database Location

```
~/.local/share/com.personal.flourish/history.db
```

(Equivalent to `NSSearchPathDirectory.applicationSupportDirectory` + `com.personal.flourish/history.db` on macOS.)

---

## Schema

### Table: `history_entry`

```sql
CREATE TABLE history_entry (
    id                  INTEGER  PRIMARY KEY AUTOINCREMENT,
    created_at          DATETIME NOT NULL,
    original_prompt     TEXT     NOT NULL,
    improved_prompt     TEXT     NOT NULL,
    provider            TEXT     NOT NULL,
    model_id            TEXT     NOT NULL,
    tokens_in           INTEGER  NOT NULL DEFAULT 0,
    tokens_out          INTEGER  NOT NULL DEFAULT 0,
    estimated_cost_usd  REAL     NOT NULL DEFAULT 0
);

CREATE INDEX idx_history_entry_created_at ON history_entry(created_at);
```

### Column descriptions

| Column | SQLite Type | Description |
|--------|-------------|-------------|
| `id` | `INTEGER` | Auto-incrementing primary key. Also the GRDB `RowID` |
| `created_at` | `DATETIME` | UTC timestamp when the improvement was completed. Indexed for fast sort/range queries |
| `original_prompt` | `TEXT` | The user's original input text |
| `improved_prompt` | `TEXT` | The LLM's improved version |
| `provider` | `TEXT` | `LLMProvider.rawValue`: `"openrouter"` or `"groq"` |
| `model_id` | `TEXT` | Exact model identifier string used for this request |
| `tokens_in` | `INTEGER` | Number of prompt tokens sent to the API |
| `tokens_out` | `INTEGER` | Number of completion tokens received |
| `estimated_cost_usd` | `REAL` | Client-calculated cost: `(tokensIn/1M * priceIn) + (tokensOut/1M * priceOut)` |

---

## Migrations

GRDB's `DatabaseMigrator` is used. All migrations run in order at app launch via `HistoryStore.setupDatabase()`.

### Migration v1 (initial)

Creates the `history_entry` table with all columns and the `created_at` index.

To add a migration for a new column, append to the migrator in `HistoryStore.swift`:

```swift
migrator.registerMigration("v2") { db in
    try db.alter(table: "history_entry") { t in
        t.add(column: "my_new_column", .text).notNull().defaults(to: "")
    }
}
```

Migrations are **never modified after merge** — always add a new numbered migration.

---

## Operations

All operations are in `HistoryStore.swift`.

### Insert

```swift
func insert(_ entry: HistoryEntry) throws
```

1. Inserts the row via `entry.insert(db)` (GRDB `MutablePersistableRecord`).
2. Counts total rows.
3. If count exceeds 500, deletes the oldest `count - 500` entries (by `created_at ASC`).

### Fetch all (with optional search)

```swift
func fetchAll(search: String = "", limit: Int = 500) throws -> [HistoryEntry]
```

- Sorted by `created_at DESC` (most recent first).
- If `search` is non-empty: filters rows where `original_prompt LIKE '%search%'` OR `improved_prompt LIKE '%search%'` (case-insensitive, SQL LIKE).
- `limit` defaults to 500 (the max entry count).

### Fetch recent (for overlay history navigation)

```swift
func fetchRecent(limit: Int = 50) throws -> [HistoryEntry]
```

Returns the 50 most recent entries sorted by `created_at DESC`. Used by `OverlayWindowController` to populate the Up/Down history navigation.

### Delete single

```swift
func delete(id: Int64) throws
```

### Delete all

```swift
func deleteAll() throws
```

### Count

```swift
func totalCount() throws -> Int
```

---

## Capacity Limit

Maximum entries: **500**. Enforced on every insert. When exceeded, the oldest rows (smallest `created_at`) are deleted first. There is no archiving or export mechanism in v1.0.0.

See [ADR-012: Max 500 History Entries](../adr/012-history-max-entries.md).

---

## Related

- [Data Models Reference](data-models.md) — `HistoryEntry` struct
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [ADR-003: GRDB over CoreData](../adr/003-grdb-over-coredata.md)
- [ADR-012: Max 500 History Entries](../adr/012-history-max-entries.md)
