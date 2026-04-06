# Data Persistence Strategy

How Flourish decides what to store in Info.plist (build-time injection), SQLite, UserDefaults, or session-only memory — and why.

---

## The four tiers

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  INFO.PLIST        Proxy URL + proxy token          │
│  (build-time)      Injected from Secrets.xcconfig.  │
│                    Read-only at runtime.             │
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

Note: The Keychain tier was previously used for OpenRouter and Groq API keys. With the move to the Cloudflare Worker proxy (ADR-015), user-facing API keys no longer exist. Provider API keys are stored as Cloudflare secrets in the Worker. The proxy bearer token is embedded in `Info.plist` at build time via `Secrets.xcconfig`.

---

## Info.plist (build-time injection): Proxy configuration

**What goes here:** `FlourishProxyURL` (hostname of the Cloudflare Worker), `FlourishProxyToken` (bearer token for authenticating to the Worker).

**Why Info.plist and not Keychain or UserDefaults:**
- These values are set at build time by the developer and do not change at runtime — they are configuration, not user data.
- The proxy token is a lower-stakes secret than a provider API key: it is proxy-specific, can be rate-limited at the Worker, and can be rotated by issuing a new build.
- Injecting via `Secrets.xcconfig` → build settings → `Info.plist` is the standard iOS/macOS pattern for build-time configuration that must not be committed to source control.

**Access pattern:**
- Read once at the start of each `FlourishProxyService.improvePrompt` call from `Bundle.main.infoDictionary`.
- Never written at runtime.

**Implementation:** `Secrets.xcconfig` (gitignored) → `FLOURISH_PROXY_URL` / `FLOURISH_PROXY_TOKEN` build settings → `Info.plist` keys `FlourishProxyURL` / `FlourishProxyToken`.

See [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md).

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
| Proxy URL + token | YES (build-time secret) | No | No | No | Info.plist (from Secrets.xcconfig) |
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
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md) — explains why proxy config is in Info.plist, not Keychain
- [ADR-010: Session Stats Separate](../adr/010-session-stats-separate.md)
- [ADR-014: Draft Saved on Dismiss](../adr/014-draft-save-on-dismiss.md)
- [Database Schema Reference](../reference/database-schema.md)
- [App Settings Reference](../reference/app-settings.md)
