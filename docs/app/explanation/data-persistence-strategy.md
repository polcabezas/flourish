# Data Persistence Strategy

How Flourish decides what to store in Keychain, SQLite, UserDefaults, or session-only memory — and why.

---

## The four tiers

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  KEYCHAIN          API keys                         │
│  (secure, small)   Encrypted by OS. Never on disk   │
│                    in plaintext.                    │
│                                                     │
│  SQLITE (GRDB)     Prompt history                   │
│  (queryable, large) Indexed. Capped at 500 rows.    │
│                    Supports search.                 │
│                                                     │
│  USERDEFAULTS      Settings, profiles, stats        │
│  (Defaults pkg)    Type-safe. Small values.         │
│  (fast, small)     Survives across launches.        │
│                                                     │
│  SESSION MEMORY    Per-launch stats, overlay draft  │
│  (in-process,      In-memory. Lost on quit.         │
│   ephemeral)       No I/O overhead.                 │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Keychain: API keys

**What goes here:** OpenRouter API key, Groq API key.

**Why Keychain and not UserDefaults:**
- UserDefaults (`~/Library/Preferences/com.personal.flourish.plist`) is a plain plist on disk — readable by anyone with access to the file.
- macOS Keychain encrypts entries using the user's login password and the OS's secure enclave where available.
- API keys are secrets with financial consequences if leaked. The Keychain is the only acceptable storage for them.

**Access pattern:**
- Written once when the user enters a key in Settings.
- Read once at the start of each `runLLM()` call.
- Never cached in memory after retrieval (the service instance is thrown away after use).

**Implementation:** `KeychainService` (service: `"com.personal.flourish"`, account: provider rawValue).

See [ADR-005: Keychain for API Keys](../adr/005-keychain-for-api-keys.md).

---

## SQLite (GRDB): Prompt history

**What goes here:** Every successful LLM improvement — original prompt, improved prompt, provider, model, token counts, cost, timestamp.

**Why SQLite and not UserDefaults:**
- History is an unbounded, growing collection. UserDefaults is designed for small, relatively static values. Encoding 500 history entries as JSON in UserDefaults would be slow to read/write and hard to query.
- SQLite provides indexed queries (search, sort by date, range filters) that would be expensive to replicate in memory from a flat JSON blob.
- GRDB gives type-safe Swift access with a simple, transparent SQL API.

**Why not CoreData:**
- History is a single table with no complex relationships. CoreData's object graph, managed object context threading model, and heavyweight stack are unnecessary overhead.
- GRDB is significantly lighter and gives direct SQL visibility.

**Capacity:** Capped at 500 entries. Enforced on every insert. See [ADR-012: Max 500 History Entries](../adr/012-history-max-entries.md).

**Location:** `~/.local/share/com.personal.flourish/history.db`

See [ADR-003: GRDB over CoreData](../adr/003-grdb-over-coredata.md).

---

## UserDefaults (Defaults package): Settings, profiles, stats

**What goes here:**
- Provider toggles, selected models, custom model IDs
- Active provider selection
- Guideline profiles (JSON-encoded array)
- Last selected profile ID
- All-time cumulative statistics (request count, tokens, cost)
- Base prompt template
- General preferences (launch at login, show dock icon)

**Why UserDefaults:**
- These are small scalar or JSON-serializable values that need to persist across launches.
- Access is fast (in-process).
- The `Defaults` package adds type-safety and Codable serialization, eliminating the risk of type mismatch bugs.

**Why Defaults package and not raw UserDefaults:**
- `Defaults.Key<T>` is typed at the call site — no casting.
- `@Default(.keyName)` property wrapper integrates directly with SwiftUI for two-way binding.
- Custom `Defaults.Serializable` conformances allow persisting complex types (like `[GuidelineProfile]`) without manual JSON encoding/decoding in every call site.

See [ADR-004: Defaults Package](../adr/004-defaults-package.md).

---

## Session memory: Per-launch stats

**What goes here:** The current session's request count, token totals, and cost. Displayed on the Home screen's session badge.

**Why not UserDefaults:**
- Session stats are intentionally ephemeral — they reset on every app launch by design.
- Writing to UserDefaults on every LLM call (just for session stats) is unnecessary I/O.
- `SessionStatsTracker` is a simple `@Published ObservableObject` singleton — SwiftUI views observe it directly.

**All-time stats** (which persist) use UserDefaults via the `totalRequestCount`, `totalTokensIn`, `totalTokensOut`, `totalCostUSD` Defaults keys. Session stats are in addition to, not a replacement for, all-time stats.

See [ADR-010: Session Stats Separate](../adr/010-session-stats-separate.md).

---

## The overlay draft: A special case

**What goes here:** The text the user typed in the overlay when they dismissed it without pasting.

**Why UserDefaults (directly, not via Defaults package):**
- The draft needs to survive app restarts — so it must be persistent.
- It's a single string + a timestamp — trivially small.
- It's written at overlay dismiss time (not on every keystroke) — I/O is infrequent.

**Why saved on dismiss, not on every keystroke:**
- Saving on every keystroke would cause continuous UserDefaults writes while the user is typing. This is noisy, unnecessary, and could cause visible latency on slow machines.
- At dismiss, the draft is already finalized (the user has stopped typing).

Keys used directly: `UserDefaults.standard.set(_, forKey: "flourish.overlayDraft")` and `"flourish.overlayDraftDate"`.

See [ADR-014: Draft Saved on Dismiss](../adr/014-draft-save-on-dismiss.md).

---

## Decision matrix

| Data | Sensitive? | Large/Growing? | Queryable? | Ephemeral? | → Store in |
|------|-----------|----------------|-----------|-----------|-----------|
| API keys | YES | No | No | No | Keychain |
| Prompt history | No | YES | YES | No | SQLite |
| Profiles | No | No (bounded) | No | No | UserDefaults |
| Settings | No | No | No | No | UserDefaults |
| All-time stats | No | No | No | No | UserDefaults |
| Session stats | No | No | No | YES | Session memory |
| Overlay draft | No | No | No | No | UserDefaults |

---

## Related

- [ADR-003: GRDB over CoreData](../adr/003-grdb-over-coredata.md)
- [ADR-004: Defaults Package](../adr/004-defaults-package.md)
- [ADR-005: Keychain for API Keys](../adr/005-keychain-for-api-keys.md)
- [ADR-010: Session Stats Separate](../adr/010-session-stats-separate.md)
- [ADR-014: Draft Saved on Dismiss](../adr/014-draft-save-on-dismiss.md)
- [Database Schema Reference](../reference/database-schema.md)
- [App Settings Reference](../reference/app-settings.md)
