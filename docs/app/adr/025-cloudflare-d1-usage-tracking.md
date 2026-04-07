# ADR-025: Cloudflare D1 for usage tracking

**Status:** Superseded by [ADR-027](027-supabase-postgres-over-d1.md)  
**Date:** 2026-04

---

## Decision

Per-user request counters and subscription state are stored in a Cloudflare D1 SQLite database (`flourish-users`) bound directly to the Worker. JWT verification uses the Web Crypto API built into the Workers runtime — no outbound fetch to Supabase is made per request.

---

## Context

Usage limits (free: 30 req/month, pro: 2000 req/month) require the Worker to know, per request:

1. Who the user is (authenticated identity)
2. What plan they are on (subscription tier)
3. How many requests they have made this month

Two sub-decisions were needed: where to store usage data, and how to verify the Supabase JWT without adding latency.

---

## Alternatives Considered for storage

### A. Supabase database (Postgres)

The Supabase project already exists for auth. Using its Postgres database for usage counters would consolidate all persistent data in one place.

Rejected because:
- Every `/improve` request would require the Worker to make an outbound HTTPS call to Supabase to read and increment the counter. This adds latency and a network dependency on every prompt improvement.
- Cloudflare Workers have a CPU time budget per invocation. An extra Supabase round-trip consumes a significant portion of it.
- Supabase Postgres is over-provisioned for a simple increment-and-compare counter pattern.

### B. Cloudflare KV

Cloudflare KV is globally distributed and eventually consistent. For usage counting, eventual consistency means two concurrent requests could both read the same "old" counter value and both be allowed even when the limit would be exceeded.

Rejected: strong consistency per-user is required for reliable limit enforcement.

### C. Cloudflare D1 (chosen)

D1 is a SQLite database co-located with the Worker in the same Cloudflare datacenter region. Reads and writes are synchronous within the same Worker invocation — no outbound fetch. D1 provides strong consistency (single-writer SQLite) without the latency of a separate service.

The `flourish-users` D1 database is bound to the Worker via `wrangler.toml`. The schema:

```sql
CREATE TABLE user_subscriptions (
    user_id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    stripe_customer_id TEXT,
    subscription TEXT NOT NULL DEFAULT 'free',
    requests_this_month INTEGER NOT NULL DEFAULT 0,
    reset_at TEXT NOT NULL
);
```

On each `/improve` request, the Worker:
1. Verifies the JWT (Web Crypto, see below)
2. Reads the row for `user_id`
3. Checks `requests_this_month` against the plan limit
4. If within limit: increments the counter, processes the LLM request, returns the response
5. If over limit: returns HTTP 429 with `{ "error": "monthly_limit_reached" }`

`reset_at` is an ISO-8601 timestamp for the start of the next billing cycle. The Worker resets `requests_this_month` to 0 when the current time exceeds `reset_at`.

---

## JWT verification via Web Crypto

Supabase JWTs are signed with HS256 using the Supabase JWT secret. Verifying them requires importing the secret as a CryptoKey and using `crypto.subtle.verify`.

This is done entirely within the Workers runtime using the Web Crypto API (`crypto.subtle`). No HTTP call to Supabase is made.

The JWT secret is stored as a Cloudflare secret (not in `wrangler.toml`) and accessed via `env.SUPABASE_JWT_SECRET`. The Worker:

1. Decodes the JWT header and payload (base64url)
2. Imports the secret as an HMAC-SHA256 key via `crypto.subtle.importKey`
3. Verifies the signature via `crypto.subtle.verify`
4. Checks `exp` (expiry) and `sub` (user ID) claims

This approach adds zero latency for auth verification and eliminates the Supabase token introspection endpoint as a dependency in the critical path.

---

## Consequences

- The `flourish-users` D1 database binding must be declared in `wrangler.toml`. The database is created separately via `wrangler d1 create flourish-users`.
- Usage data lives in Cloudflare, not Supabase. The `GET /account/usage` Worker route reads from D1 and returns current plan, usage count, and reset date to `AccountViewModel`.
- The `POST /account/create` route is called by `AuthService.shared.ensureAccountExists()` after the first sign-in. It creates a row in `user_subscriptions` if one does not already exist (idempotent — safe to call on every login).
- Monthly resets are lazy: the counter is only reset when a new request arrives after `reset_at`. There is no scheduled job.
- The 429 `monthly_limit_reached` error is handled by `flourishProxyService`, which maps it to a dedicated `LLMError` case displayed to the user.

---

## Related

- [ADR-015: Cloudflare Worker Proxy](015-cloudflare-worker-proxy.md)
- [ADR-023: Supabase Auth Strategy](023-supabase-auth-strategy.md)
- [ADR-026: Stripe Billing via Worker](026-stripe-billing-via-worker.md)
- [File Structure Reference](../reference/file-structure.md)
