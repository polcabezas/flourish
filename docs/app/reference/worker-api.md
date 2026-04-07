# Worker API Reference

Request and response contracts for all Cloudflare Worker endpoints. The Worker is the sole intermediary between the Flourish app and external services (LLM providers, Supabase, Stripe).

**Base URL:** `https://flourish-proxy.<subdomain>.workers.dev` (value of `flourish_PROXY_URL` in `Secrets.xcconfig`)

**Authentication:** All routes except `/stripe/webhook` require a valid Supabase JWT in the `Authorization` header:

```
Authorization: Bearer <supabase-access-token>
```

The Worker supports both ES256 (ECDSA P-256, default for new Supabase projects) and HS256 (HMAC-SHA256) JWTs, auto-detected from the token header.

---

## Routes Summary

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| [`/improve`](#post-improve) | POST | JWT | Forward prompt to LLM, check and increment usage |
| [`/account/create`](#post-accountcreate) | POST | JWT | Idempotent upsert of user row (safety net) |
| [`/account/usage`](#get-accountusage) | GET | JWT | Return plan, usage count, limit, and reset date |
| [`/billing/checkout`](#post-billingcheckout) | POST | JWT | Create a Stripe Checkout Session |
| [`/billing/portal`](#get-billingportal) | GET | JWT | Create a Stripe Billing Portal session |
| [`/stripe/webhook`](#post-stripewebhook) | POST | Stripe signature | Handle subscription and invoice events |

---

## `POST /improve`

Forwards the user's prompt to the configured LLM provider. Checks the monthly request limit before forwarding and increments the counter atomically after a successful call.

### Request

```http
POST /improve
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "messages": [
    { "role": "system", "content": "You are a writing assistant. Improve the text." },
    { "role": "user", "content": "Make this better: hello world" }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `messages` | array | Yes | OpenAI-compatible chat messages array. Built by `flourishProxyService` from the system prompt (`BasePrompt.build(guidelines:targetPlatform:)`) and the user's input text. The active model is controlled server-side via `ACTIVE_MODEL` in `wrangler.toml` — the client does not send a model override. |

### Response — 200 OK

The Worker passes through the raw response from the upstream LLM provider unchanged, adding only an `X-flourish-Provider` header. Both Groq and OpenRouter use the OpenAI-compatible chat completions format:

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Hello, world! Welcome to a better greeting."
      },
      "finish_reason": "stop"
    }
  ],
  "model": "llama-3.1-8b-instant",
  "usage": {
    "prompt_tokens": 42,
    "completion_tokens": 17,
    "total_tokens": 59
  }
}
```

`flourishProxyService` reads `choices[0].message.content` for the improved text and `usage` for token counts.

### Response — 429 Too Many Requests (monthly limit reached)

```json
{
  "error": "monthly_limit_reached",
  "plan": "free",
  "limit": 30
}
```

Handled by `flourishProxyService` as `LLMError.monthlyLimitReached`. Triggers `LimitReachedWindowController.shared.show()` — a bottom-center floating popup with an upgrade CTA and a 12-second auto-dismiss timer. See ADR-033.

### Plan limits

| Plan | Monthly limit |
|------|--------------|
| `free` | 30 requests |
| `pro` | Unlimited (`PLAN_LIMITS.pro = null` — no 429 is ever returned for Pro users) |

Monthly counters reset lazily: the Worker checks whether the current date has passed `reset_at + 1 month`. If so, it resets `requests_this_month` to 0 and updates `reset_at` before processing the request.

---

## `POST /account/create`

Idempotent upsert of the user's row in `user_subscriptions`. Called by `AuthService.ensureAccountExists()` after the first successful sign-in.

In normal operation, the row is created by the Supabase `on_auth_user_created` trigger before this route is ever called. This route is a safety net for users created before the trigger existed.

### Request

```http
POST /account/create
Authorization: Bearer <jwt>
Content-Type: application/json
```

Body: empty (`{}`) — user identity is extracted from the JWT.

### Response — 200 OK

```json
{
  "ok": true
}
```

This response is the same whether a new row was created or an existing row was left unchanged.

### Response — 401 Unauthorized

JWT is missing, expired, or invalid. `AuthService` retries once after refreshing the session token.

---

## `GET /account/usage`

Returns the authenticated user's current plan, usage counter, monthly limit, and reset date.

### Request

```http
GET /account/usage
Authorization: Bearer <jwt>
```

### Response — 200 OK

```json
{
  "plan": "free",
  "requests_this_month": 7,
  "limit": 30,
  "reset_at": "2026-04-01"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `plan` | string | `"free"` or `"pro"` |
| `requests_this_month` | integer | Requests made in the current billing period |
| `limit` | integer \| null | Monthly request cap for the plan: `30` for free, `null` for pro (unlimited) |
| `reset_at` | string | ISO-8601 date (`YYYY-MM-DD`) of the **start** of the current billing period |

Note: `reset_at` stores the period start, not the next reset. `AccountViewModel` adds one month before displaying to the user (e.g. `"2026-04-01"` → shown as "resets May 1").

---

## `POST /billing/checkout`

Creates a Stripe Checkout Session for the authenticated user. If the user has no Stripe customer record yet, one is created lazily at this point.

### Request

```http
POST /billing/checkout
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "billing_period": "monthly"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `billing_period` | string | Yes | `"monthly"` or `"yearly"`. Selects the Stripe price ID |

The app's `BillingPeriod` enum maps display values to API values:
- `.monthly` → `"monthly"` → `STRIPE_PRO_PRICE_ID_MONTHLY`
- `.annual` → `"yearly"` → `STRIPE_PRO_PRICE_ID_YEARLY`

### Response — 200 OK

```json
{
  "url": "https://checkout.stripe.com/c/pay/cs_test_..."
}
```

`AccountViewModel` opens this URL via `NSWorkspace.shared.open(_:)`. The URL is a single-use Stripe Checkout Session valid for ~24 hours.

### Stripe redirect URLs

After payment, Stripe redirects to:
- **Success:** `https://flourish.app/billing/success`
- **Cancel:** `https://flourish.app/billing/cancel`

These are static HTTPS URLs (Stripe requires HTTPS). The app does not handle the redirect. Subscription state is updated via the Stripe webhook.

### Response — 429 Too Many Requests (already subscribed)

If the user is already on Pro, a checkout session is not created.

---

## `GET /billing/portal`

Creates a Stripe Billing Portal session for the authenticated user. Allows managing or cancelling an existing subscription.

### Request

```http
GET /billing/portal
Authorization: Bearer <jwt>
```

### Response — 200 OK

```json
{
  "url": "https://billing.stripe.com/p/session/..."
}
```

`AccountViewModel` opens this URL via `NSWorkspace.shared.open(_:)`. The URL is single-use and expires after ~5 minutes (Stripe default). `AccountViewModel` fetches a fresh URL on every tap — it does not cache the URL.

### Response — 404 Not Found

User has no Stripe customer record (has never initiated checkout).

---

## `POST /stripe/webhook`

Receives and verifies Stripe webhook events. Updates the user's subscription tier in Supabase based on the event type.

### Authentication

This route does **not** use JWT authentication. It verifies the `Stripe-Signature` header using `STRIPE_WEBHOOK_SECRET` via HMAC-SHA256 (Web Crypto API).

### Handled events

| Event | Action |
|-------|--------|
| `customer.subscription.updated` | Sets `subscription` to `'pro'` if status is `active`, otherwise `'free'` |
| `customer.subscription.deleted` | Sets `subscription` to `'free'` |
| `invoice.paid` | Resets `requests_this_month` to `0` and updates `reset_at` to the current month start |

### Request

```http
POST /stripe/webhook
Stripe-Signature: t=1234567890,v1=abc123...
Content-Type: application/json

{ ...stripe event object... }
```

### Response — 200 OK

```json
{ "received": true }
```

### Response — 400 Bad Request

Signature verification failed. The request is rejected.

---

## Error format

All error responses use the same shape:

```json
{
  "error": "<error_code_or_message>"
}
```

Common error codes:

| Code | HTTP status | Meaning |
|------|-------------|---------|
| `unauthorized` | 401 | JWT missing, expired, or invalid |
| `monthly_limit_reached` | 429 | User has exceeded their plan's monthly request limit |
| `invalid_billing_period` | 400 | `billing_period` was not `"monthly"` or `"yearly"` |

---

## Related

- [Deploy or Update the Cloudflare Worker](../how-to/deploy-worker.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [ADR-026: Stripe billing via Worker](../adr/026-stripe-billing-via-worker.md)
- [ADR-027: Supabase PostgreSQL over D1](../adr/027-supabase-postgres-over-d1.md)
- [ADR-028: ES256 JWT verification](../adr/028-es256-jwt-verification.md)
- [Database Schema Reference](database-schema.md)
