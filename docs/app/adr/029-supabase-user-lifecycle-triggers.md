# ADR-029: Supabase database triggers for user lifecycle

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

User subscription rows are created and deleted by **PostgreSQL triggers on `auth.users`**, not by the Cloudflare Worker. A trigger on INSERT auto-creates the `user_subscriptions` row when a user signs up. A trigger on DELETE cascades the deletion. The Worker's `ensureUserRow` call is retained as a safety net but is no longer the primary creation mechanism.

---

## Context

With D1, the only way to create a `user_subscriptions` row was for the Worker's `POST /account/create` route to succeed. `AuthService.ensureAccountExists()` calls this route after every sign-in. This created a fragile dependency chain:

1. User signs in → Supabase issues a JWT
2. App calls `POST /account/create` with the JWT
3. Worker verifies JWT → if JWT algorithm mismatch (see ADR-028), Worker returns 401
4. `ensureAccountExists` silently discards the error (`_ = try? await URLSession.shared.data(for: req)`)
5. No row is created → every subsequent `/improve` call returns 500 (Worker tries to read a null row)

The result: users could sign in successfully but the app appeared broken (`"Sign in to use flourish."` from `LLMError.unauthorized`). The root cause was invisible without log access.

The same fragility applies at deletion: if the Worker fails to clean up the row (e.g., it is not called at all when a user is deleted from the Supabase dashboard), the row becomes an orphan and leaks Stripe customer IDs.

---

## Alternatives Considered

### A. Worker-only creation (original approach)

`POST /account/create` is called on every sign-in. Idempotent by design (`ON CONFLICT DO NOTHING`). Rejected as the primary mechanism because it is downstream of JWT auth — any auth misconfiguration silently blocks row creation.

### B. Foreign key with ON DELETE CASCADE

Adding a proper FK from `user_subscriptions.user_id` to `auth.users.id` would cascade deletes automatically. Blocked by a type mismatch: `user_id` is `TEXT` and `auth.users.id` is `UUID`. Changing `user_id` to `UUID` would require a migration of any existing data. A trigger provides the same behaviour without the type change.

### C. Supabase database triggers (chosen)

PostgreSQL triggers fire synchronously within the same transaction as the originating INSERT/DELETE on `auth.users`. The row is guaranteed to exist by the time the new user's first request reaches the Worker.

```sql
-- Creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.user_subscriptions
    (user_id, email, subscription, requests_this_month, reset_at)
  VALUES (
    NEW.id::text,
    COALESCE(NEW.email, ''),
    'free', 0,
    to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-01')
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Deletion trigger
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

`SECURITY DEFINER` ensures the functions run with the privileges of the function owner (typically the Supabase service role), not the role of the triggering session.

---

## Backfill for existing users

The triggers only fire on future INSERT/DELETE events. Existing users require a one-time backfill:

```sql
INSERT INTO public.user_subscriptions
  (user_id, email, subscription, requests_this_month, reset_at)
SELECT
  id::text,
  COALESCE(email, ''),
  'free', 0,
  to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-01')
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;
```

---

## Consequences

- **Row creation is now database-internal.** The `POST /account/create` Worker route still exists and is still called by `AuthService.ensureAccountExists()`, but it is a no-op (idempotent upsert) if the trigger has already created the row.
- **Row deletion is automatic.** Deleting a user from Supabase Authentication → Users also removes their `user_subscriptions` row and all associated state (including `stripe_customer_id`).
- **No Stripe cleanup on deletion.** The trigger does not cancel an active Stripe subscription. If a user with an active Pro subscription is deleted, their Stripe subscription continues billing until manually cancelled in the Stripe dashboard. A more complete deletion flow would call the Stripe API; this is out of scope for now.
- The trigger approach is only available because storage moved to Supabase PostgreSQL (ADR-027). It was not possible with Cloudflare D1.

---

## Related

- [ADR-027: Supabase PostgreSQL over D1](027-supabase-postgres-over-d1.md)
- [ADR-023: Supabase Auth strategy](023-supabase-auth-strategy.md)
- [ADR-026: Stripe billing via Worker](026-stripe-billing-via-worker.md)
