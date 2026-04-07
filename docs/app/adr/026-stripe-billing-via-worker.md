# ADR-026: Stripe billing logic in the Cloudflare Worker

**Status:** Accepted — see also [ADR-027](027-supabase-postgres-over-d1.md), [ADR-030](030-plans-billing-ui.md)  
**Date:** 2026-04

---

## Decision

All Stripe billing operations — Checkout Session creation, Billing Portal access, and webhook handling — are implemented as routes in the existing Cloudflare Worker. No separate billing service or backend is introduced. Stripe customers are created lazily (on first checkout, not on account creation). Webhook signature verification uses the Web Crypto API built into the Workers runtime.

---

## Context

flourish needed a billing system to monetize the app. The options were:

1. Add billing routes to the existing Cloudflare Worker
2. Deploy a separate backend service (Node.js, Deno, etc.) to handle Stripe interactions
3. Use a third-party billing abstraction (Paddle, Lemon Squeezy, etc.)

The app already has a Cloudflare Worker that handles LLM proxying, JWT verification, and D1 usage tracking. The Worker has access to all necessary data: user identity (from JWT), subscription state (from D1), and Stripe credentials (from Cloudflare secrets).

---

## Alternatives Considered

### A. Separate billing backend

Rejected. Introducing a second backend service creates operational overhead (deployment, monitoring, secrets management) for functionality that the existing Worker can provide. The Stripe Node.js SDK works in the Cloudflare Workers runtime. No new infrastructure is needed.

### B. Third-party billing abstraction (Paddle, Lemon Squeezy)

Considered. These services handle tax, compliance, and checkout UI themselves. Rejected because:
- They add a vendor between flourish and Stripe, with their own fee structures and integration complexity
- Stripe's direct integration provides more control over the checkout experience and webhook reliability
- Switching later is feasible; the cost of the direct integration now is low given the Worker already exists

### C. Billing in the Worker alongside existing routes (chosen)

The Worker gains three new routes:

| Route | Method | Purpose |
|-------|--------|---------|
| `/billing/checkout` | POST | Create a Stripe Checkout Session (monthly or yearly price ID) |
| `/billing/portal` | GET | Create a Stripe Billing Portal session for the authenticated user |
| `/stripe/webhook` | POST | Handle `customer.subscription.updated` and `customer.subscription.deleted` events |

---

## Lazy Stripe Customer Creation

A Stripe `Customer` object is created only when the user first initiates checkout (`POST /billing/checkout`), not when they create an account.

Rationale:
- Free-plan users who never upgrade do not generate Stripe API calls or customer records
- Checkout is the natural moment to create a customer: the user is actively expressing intent to pay
- `POST /account/create` (called on every first login) does not need Stripe credentials or API access, keeping the account creation path simple

On checkout:
1. Worker checks D1 for `stripe_customer_id`
2. If `null`: calls `stripe.customers.create({ email })`, saves the returned ID to D1
3. Creates a `stripe.checkout.sessions.create` with the customer ID and the requested price ID

---

## Webhook Signature Verification via Web Crypto

Stripe webhook payloads include a `Stripe-Signature` header with an HMAC-SHA256 signature over the raw request body and a timestamp. Verification requires the Stripe webhook secret.

The Workers runtime does not include the Stripe SDK's `webhooks.constructEvent` method (which uses the `crypto` Node.js module). The signature is verified manually using `crypto.subtle`:

1. Parse the `Stripe-Signature` header to extract `t` (timestamp) and `v1` (signature)
2. Construct the signed payload: `${t}.${rawBody}`
3. Import `env.STRIPE_WEBHOOK_SECRET` as an HMAC-SHA256 key
4. Compute the expected signature via `crypto.subtle.sign`
5. Compare to `v1` using a constant-time comparison

This approach has no dependencies on Node.js-specific modules and runs entirely within the Workers runtime.

---

## Subscription State Synchronization

The Worker updates D1 on two triggers:

1. **Webhook** (`customer.subscription.updated`): sets `subscription` to `'pro'` or `'free'` based on the Stripe subscription status
2. **Webhook** (`customer.subscription.deleted`): sets `subscription` back to `'free'`

The app's `AccountViewModel` calls `GET /account/usage` to fetch current plan and usage. `AccountView` displays the plan tier and usage progress. The `lastKnownSubscription` Defaults key caches the last-known tier locally so the UI can render before the network response arrives.

The app does not poll for subscription changes. If a webhook is delivered while the app is closed, the next `GET /account/usage` on next launch reflects the updated state.

---

## Billing UI in the App

`AccountView` (in the main window's `.account` section) provides:
- Email address and plan badge (Free / Pro)
- Usage progress bar: requests used this month / limit
- Reset date for the monthly counter
- Sign Out button
- Billing section: monthly/yearly toggle + Upgrade / Manage Billing button

`AccountViewModel` handles:
- Fetching `UsageInfo` from `GET /account/usage`
- Calling `POST /billing/checkout` and opening the returned `url` via `NSWorkspace.shared.open(_:)`
- Calling `GET /billing/portal` and opening the returned `url` via `NSWorkspace.shared.open(_:)`

Checkout and portal sessions open in the user's default browser. After payment, Stripe redirects back to a success URL (external, not the app). Subscription state is updated via the webhook.

---

## Consequences

- The Worker now handles five route categories: LLM proxying, account management, usage tracking, billing, and Stripe webhooks. `worker.js` is significantly larger than in ADR-015. If complexity grows further, splitting into separate Workers (or using Cloudflare Pages Functions) should be reconsidered.
- `wrangler.toml` must declare the D1 database binding (`flourish-users`) and the following Cloudflare secrets: `SUPABASE_JWT_SECRET`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_MONTHLY_PRICE_ID`, `STRIPE_YEARLY_PRICE_ID`.
- The billing portal URL is single-use and short-lived (Stripe default: 5 minutes). `AccountViewModel` fetches a fresh URL on each tap of the Manage Billing button — it does not cache the URL.
- Plan limits are enforced in D1 at the Worker level. There is no client-side enforcement.

---

## Related

- [ADR-015: Cloudflare Worker Proxy](015-cloudflare-worker-proxy.md)
- [ADR-023: Supabase Auth Strategy](023-supabase-auth-strategy.md)
- [ADR-025: Cloudflare D1 Usage Tracking](025-cloudflare-d1-usage-tracking.md)
- [Architecture Overview](../reference/architecture-overview.md)
