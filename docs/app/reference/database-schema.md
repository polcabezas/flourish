# Database Schema Reference

The SQLite database used by flourish for prompt history storage, managed via the GRDB Swift package.

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
- [Supabase user_subscriptions table](#supabase-user_subscriptions-table)

---

## Supabase: `user_subscriptions` table

Per-user subscription state and monthly usage counters live in Supabase PostgreSQL, accessed by the Cloudflare Worker via the Supabase REST API using the `service_role` key.

### Connection

- **Project URL:** configured as `SUPABASE_URL` in `wrangler.toml` (public, non-secret)
- **Auth:** `SUPABASE_SERVICE_ROLE_KEY` Cloudflare secret — bypasses Row Level Security; used only by the Worker
- **Access pattern:** Worker makes HTTPS calls to `${SUPABASE_URL}/rest/v1/user_subscriptions`

### Schema

```sql
CREATE TABLE IF NOT EXISTS user_subscriptions (
  user_id             TEXT PRIMARY KEY,
  email               TEXT NOT NULL,
  stripe_customer_id  TEXT,
  subscription        TEXT NOT NULL DEFAULT 'free',
  requests_this_month INTEGER NOT NULL DEFAULT 0,
  reset_at            TEXT NOT NULL DEFAULT to_char(NOW(), 'YYYY-MM-01')
);
```

### Column descriptions

| Column | Type | Description |
|--------|------|-------------|
| `user_id` | `TEXT` | Supabase Auth `uid` (UUID as string). Primary key |
| `email` | `TEXT` | User's email from Supabase Auth |
| `stripe_customer_id` | `TEXT` | Stripe `cus_…` ID. `NULL` until first checkout |
| `subscription` | `TEXT` | `'free'` or `'pro'`. Updated by Stripe webhooks |
| `requests_this_month` | `INTEGER` | Counter, incremented atomically via RPC on each `/improve` call |
| `reset_at` | `TEXT` | ISO-8601 date `YYYY-MM-DD` of the start of the current billing period (e.g. `"2026-04-01"`). Worker resets counter when current date exceeds this value + 1 month |

### RPC: `increment_user_requests`

An atomic increment function to avoid race conditions from concurrent requests:

```sql
CREATE OR REPLACE FUNCTION increment_user_requests(p_user_id TEXT)
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE user_subscriptions
  SET requests_this_month = requests_this_month + 1
  WHERE user_id = p_user_id;
$$;
```

Called by the Worker via `POST /rest/v1/rpc/increment_user_requests` with `{ "p_user_id": "<uid>" }`.

### Row Level Security

```sql
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid()::text = user_id);
```

- Users can `SELECT` their own row using the Supabase anon/user JWT.
- All writes (INSERT, UPDATE, DELETE) are performed exclusively by the Worker using the `service_role` key, which bypasses RLS.

### User lifecycle triggers

Rows are created and deleted automatically by PostgreSQL triggers:

```sql
-- Auto-create on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.user_subscriptions (user_id, email, subscription, requests_this_month, reset_at)
  VALUES (NEW.id::text, COALESCE(NEW.email, ''), 'free', 0,
          to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-01'))
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-delete on account deletion
CREATE OR REPLACE FUNCTION public.handle_user_deleted()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.user_subscriptions WHERE user_id = OLD.id::text;
  RETURN OLD;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_deleted
  AFTER DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_deleted();
```

The Worker's `POST /account/create` route performs an idempotent upsert as a safety net (e.g. for users created before the trigger existed).

Note: When a user is deleted, the trigger removes their `user_subscriptions` row but does **not** cancel their Stripe subscription. Stripe subscription cancellation must be handled separately via the Stripe dashboard or API before deleting the Supabase user.

### Viewing data

Supabase dashboard → Table Editor → `user_subscriptions`. All user data (plan, usage, Stripe customer ID) is visible here.

---

## Related

- [Worker API Reference](worker-api.md)
- [ADR-027: Supabase PostgreSQL over D1](../adr/027-supabase-postgres-over-d1.md)
- [ADR-029: Supabase user lifecycle triggers](../adr/029-supabase-user-lifecycle-triggers.md)
- [ADR-023: Supabase Auth strategy](../adr/023-supabase-auth-strategy.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
