# ADR-039: Use `in` operator for nullable plan limit lookup in the Worker

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use the `in` operator — not `??` (nullish coalescing) — to resolve a user's plan limit in the Cloudflare Worker, so that `null` (unlimited) is preserved rather than collapsed to the free-plan fallback.

```js
// Before — INCORRECT: null ?? 30 evaluates to 30
const limit = PLAN_LIMITS[row.subscription] ?? PLAN_LIMITS.free;

// After — CORRECT: null is kept as-is; unknown plans fall back to free
const limit = row.subscription in PLAN_LIMITS ? PLAN_LIMITS[row.subscription] : PLAN_LIMITS.free;
```

This applies to both the `POST /improve` gate and the `GET /account/usage` response.

---

## Context

`PLAN_LIMITS` is defined as `{ free: 30, pro: null }` where `null` signals "no limit". JavaScript's `??` operator returns the right-hand side when the left side is **`null` or `undefined`**. Therefore `PLAN_LIMITS["pro"] ?? PLAN_LIMITS.free` evaluates to `30` — silently giving Pro users the free plan ceiling.

The symptom: Pro users saw `"0 / 2.000 requests this month"` in the account view (the residual value from an earlier `pro: 2000` deploy) or `"0 / 30 requests this month"` on a fresh deploy, instead of `"Unlimited requests"`.

The `in` operator checks key existence independently of the associated value, so `null` is returned as intended when the key is present.

---

## Alternatives Considered

### A. Change `PLAN_LIMITS.pro` to `undefined`

`undefined ?? PLAN_LIMITS.free` → `30` (same problem). Rejected: `undefined` is semantically "not set", whereas `null` is "explicitly no limit" — the distinction matters when the object is JSON-serialised.

### B. Explicit `=== undefined` guard

```js
const raw = PLAN_LIMITS[row.subscription];
const limit = raw === undefined ? PLAN_LIMITS.free : raw;
```

Equivalent but less idiomatic than the ternary with `in`. Rejected in favour of readability.

### C. Sentinel value (e.g. `Infinity` or `-1`)

Would require changes to the Swift decoder and all downstream limit checks. Rejected: `null` is already the conventional JSON representation of "no limit" and the Swift `Int?` type already models it.

---

## Consequences

- **Worker (`cloudflare/worker.js`):** Two `const limit = …` lines updated (in `handleImprove` and `handleAccountUsage`).
- **`GET /account/usage`:** Pro users receive `"limit": null`; Swift `UsageInfo.limit` is `nil`; `AccountView` shows "Unlimited requests" with no progress bar and no reset date.
- **Free users:** Unchanged — `PLAN_LIMITS["free"]` is `30`; the `in` branch returns `30` as before.

---

## Related

- [ADR-034: Unlimited improvements for the Pro plan](034-unlimited-pro-plan.md)
- [ADR-026: Stripe billing via Worker](026-stripe-billing-via-worker.md)
- [ADR-030: Plans and Billing UI](030-plans-billing-ui.md)
