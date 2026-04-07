# ADR-027: Supabase PostgreSQL over Cloudflare D1 for usage storage

**Status:** Accepted — supersedes [ADR-025](025-cloudflare-d1-usage-tracking.md)  
**Date:** 2026-04

---

## Decision

Move all per-user data — subscription state, request counters, Stripe customer IDs — from Cloudflare D1 to the existing Supabase PostgreSQL database. The Worker accesses Supabase via its REST API using the `service_role` key. D1 binding is removed from `wrangler.toml`.

---

## Context

ADR-025 chose Cloudflare D1 to avoid an outbound network call from the Worker on every `/improve` request. The rationale was sound at the time, but a significant operational cost emerged: **usage data was invisible from the Supabase dashboard**.

Querying the `user_subscriptions` table required the Cloudflare CLI:

```bash
wrangler d1 execute flourish-users --command "SELECT * FROM user_subscriptions"
```

This meant:
- No at-a-glance visibility into user counts, plan distribution, or anomalies
- A second database to provision, back up, and reason about
- Auth data in Supabase, usage data in D1 — two sources of truth per user

At flourish's current scale the latency advantage of D1 (same-datacenter read) over a Supabase REST call (~30–80 ms round-trip) does not outweigh the operational cost.

---

## Alternatives Considered

### A. Keep Cloudflare D1

The original choice. Rejected on operational grounds: data split across two services, no dashboard visibility, requires Cloudflare CLI for any usage query. The latency argument only matters at higher request volumes than flourish currently has.

### B. Cloudflare KV

Considered as an intermediate option. Rejected for the same consistency reason as ADR-025: KV is eventually consistent, which makes reliable plan-limit enforcement impossible.

### C. Supabase PostgreSQL (chosen)

The Supabase project already exists for auth. Moving usage data to the same database means:
- Single Supabase Table Editor view for all per-user state
- SQL queries, filters, and exports from the dashboard
- One fewer service to manage

The Worker calls `https://<project>.supabase.co/rest/v1/user_subscriptions` using the `service_role` key, which bypasses Row Level Security and provides full read/write access without exposing user data to clients.

---

## Schema

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

`user_id` is the Supabase `auth.users.id` cast to `TEXT`. `reset_at` stores the ISO-8601 start date of the current billing period (e.g. `"2026-04-01"`). The Worker resets `requests_this_month` to `0` when `reset_at` is before the current month start.

### Atomic increment

`requests_this_month` is incremented via a PostgreSQL function to avoid race conditions on concurrent requests from the same user:

```sql
CREATE OR REPLACE FUNCTION increment_user_requests(p_user_id TEXT)
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE user_subscriptions
  SET requests_this_month = requests_this_month + 1
  WHERE user_id = p_user_id;
$$;
```

The Worker calls this via the Supabase RPC endpoint (`POST /rest/v1/rpc/increment_user_requests`) instead of a PATCH with a client-computed new value.

---

## Row Level Security

RLS is enabled. The `service_role` key used by the Worker bypasses RLS entirely. The single policy restricts direct client access:

```sql
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid()::text = user_id);
```

No INSERT, UPDATE, or DELETE policies are defined for client keys — all writes go through the Worker.

---

## Worker changes

The D1 helper functions (`env.DB.prepare(...).bind(...).run()`) are replaced with `fetch` calls to the Supabase REST API:

| Operation | Endpoint |
|-----------|----------|
| Read row | `GET /rest/v1/user_subscriptions?user_id=eq.<id>&select=*` |
| Upsert row | `POST /rest/v1/user_subscriptions` with `Prefer: resolution=ignore-duplicates` |
| Update fields | `PATCH /rest/v1/user_subscriptions?user_id=eq.<id>` |
| Increment counter | `POST /rest/v1/rpc/increment_user_requests` |
| Update by Stripe ID | `PATCH /rest/v1/user_subscriptions?stripe_customer_id=eq.<id>` |

All requests carry `apikey: <service_role_key>` and `Authorization: Bearer <service_role_key>` headers.

---

## New environment variables

| Variable | Type | Purpose |
|----------|------|---------|
| `SUPABASE_URL` | plain var (`wrangler.toml`) | Supabase project base URL (e.g. `https://xyz.supabase.co`) |
| `SUPABASE_SERVICE_ROLE_KEY` | secret (`wrangler secret put`) | Full read/write access to Supabase REST API |

`SUPABASE_JWT_SECRET` is retained for JWT verification (see ADR-028).

---

## Consequences

- `wrangler.toml` no longer contains a `[[d1_databases]]` binding. The `flourish-users` D1 database can be deleted via the Cloudflare dashboard after data is confirmed migrated.
- All per-user data is now visible in Supabase → Table Editor → `user_subscriptions`.
- The `POST /account/create` Worker route (`ensureUserRow`) is now a safety net only — the primary row-creation mechanism is a Supabase database trigger (see ADR-029).
- Latency on `/improve` increases by one Supabase round-trip per request (~30–80 ms) compared to D1. Acceptable at current scale; revisit if p99 latency becomes a user-visible issue.

---

## Related

- [ADR-025: Cloudflare D1 usage tracking](025-cloudflare-d1-usage-tracking.md) (superseded)
- [ADR-028: ES256 JWT verification](028-es256-jwt-verification.md)
- [ADR-029: Supabase user lifecycle triggers](029-supabase-user-lifecycle-triggers.md)
- [ADR-026: Stripe billing via Worker](026-stripe-billing-via-worker.md)
