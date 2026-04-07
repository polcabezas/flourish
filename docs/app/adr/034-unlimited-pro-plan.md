# ADR-034: Unlimited improvements for the Pro plan

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Remove the monthly request cap for Pro users. The Worker enforces no limit when `PLAN_LIMITS.pro` is `null`; the `GET /account/usage` response returns `"limit": null` for Pro users; and all UI copy reads "Unlimited" instead of a numeric ceiling.

---

## Context

The original Pro plan cap was 2,000 requests/month — chosen as a conservative upper bound during early development. In practice:

- Real users do not approach 2,000 prompt improvements per month.
- A numeric cap creates a perception of scarcity that weakens the Pro value proposition.
- "Unlimited" is a stronger, simpler marketing message than "2,000/month".
- Removing enforcement code for Pro simplifies the Worker hot path.

---

## Alternatives Considered

### A. Keep 2,000 but raise it (e.g. 10,000)

Rejected: any finite number invites the question "what happens when I hit it?" and requires ongoing maintenance if the number needs raising again. Unlimited removes the question entirely.

### B. Keep the cap but hide it from UI

Rejected: cap still enforced on the backend; users who hit it would see an unexpected error. Inconsistent with "unlimited" marketing.

### C. Unlimited with a hidden soft-limit and manual intervention

Rejected as premature. If abuse becomes a real problem, a per-minute rate limit is the right countermeasure — not a monthly ceiling.

---

## Consequences

- **Worker (`cloudflare/worker.js`):** `PLAN_LIMITS.pro = null`. The limit-check gate is skipped when `limit === null`. Pro users never receive a `monthly_limit_reached` 429.
- **`GET /account/usage`:** Returns `"limit": null` for Pro users. Free users still receive `"limit": 30`.
- **Swift models:** `UsageInfo.limit` and `UsageResponse.limit` are `Int?`. `AccountView` shows "Unlimited requests" (no progress bar) when `limit` is nil.
- **`AccountView` Pro features list:** First bullet is "Unlimited improvements".
- **Docs:** `worker-api.md`, `data-models.md`, `manage-account.md` updated accordingly.

---

## Related

- [ADR-027: Supabase PostgreSQL over D1 for usage storage](027-supabase-postgres-over-d1.md)
- [ADR-030: Plans and Billing UI](030-plans-billing-ui.md)
- [ADR-033: Separate floating popup for monthly limit reached UI](033-limit-reached-popup-window.md)
