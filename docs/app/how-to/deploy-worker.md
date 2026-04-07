# Deploy or Update the Cloudflare Worker

How to deploy the flourish proxy Worker for the first time, rotate secrets, set up Supabase storage, and configure Stripe billing.

This guide is for founders and developers with access to the Cloudflare, Supabase, and Stripe accounts. End users have no interaction with the Worker.

---

## Prerequisites

- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) installed: `npm install -g wrangler`
- Authenticated to Cloudflare: `wrangler login`
- Access to the project's `cloudflare/` directory
- Access to the Supabase project dashboard
- Access to the Stripe dashboard

---

## First-time deployment

### 1. Configure provider, model, and Supabase URL

Edit `cloudflare/wrangler.toml`:

```toml
[vars]
ACTIVE_PROVIDER = "groq"          # or "openrouter"
ACTIVE_MODEL    = "llama-3.1-8b-instant"
SUPABASE_URL    = "https://<your-project-ref>.supabase.co"
```

`SUPABASE_URL` is used to fetch the Supabase JWKS endpoint for ES256 JWT verification. It is not a secret — it is public information.

### 2. Set all secrets

Secrets are encrypted and never visible in logs or the Cloudflare dashboard. Set each one:

```bash
cd cloudflare/

# Supabase
wrangler secret put SUPABASE_JWT_SECRET
# Paste from: Supabase dashboard → Project Settings → API → JWT Secret

wrangler secret put SUPABASE_SERVICE_ROLE_KEY
# Paste from: Supabase dashboard → Project Settings → API → service_role key

# LLM providers
wrangler secret put GROQ_API_KEY
wrangler secret put OPENROUTER_API_KEY

# Stripe
wrangler secret put STRIPE_SECRET_KEY
# sk_test_… (test) or sk_live_… (production) from Stripe dashboard → Developers → API keys

wrangler secret put STRIPE_WEBHOOK_SECRET
# From Stripe dashboard → Developers → Webhooks → your endpoint → Signing secret
# (Create the webhook endpoint first — see step 5)

wrangler secret put STRIPE_PRO_PRICE_ID_MONTHLY
# Price ID from Stripe dashboard → Products → Pro → Monthly price (price_…)

wrangler secret put STRIPE_PRO_PRICE_ID_YEARLY
# Price ID from Stripe dashboard → Products → Pro → Annual price (price_…)
```

### 3. Set up the Supabase database

In Supabase dashboard → SQL Editor, run:

```sql
-- User subscription table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  user_id             TEXT PRIMARY KEY,
  email               TEXT NOT NULL,
  stripe_customer_id  TEXT,
  subscription        TEXT NOT NULL DEFAULT 'free',
  requests_this_month INTEGER NOT NULL DEFAULT 0,
  reset_at            TEXT NOT NULL DEFAULT to_char(NOW(), 'YYYY-MM-01')
);

-- Atomic increment to avoid race conditions
CREATE OR REPLACE FUNCTION increment_user_requests(p_user_id TEXT)
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE user_subscriptions
  SET requests_this_month = requests_this_month + 1
  WHERE user_id = p_user_id;
$$;

-- Row Level Security
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid()::text = user_id);

-- Auto-create row when user signs up
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

-- Auto-delete row when user is deleted
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

### 4. Set Supabase JWT algorithm to HS256 (optional)

If your Supabase project was created recently it uses ES256 by default. The Worker supports both ES256 and HS256 automatically — no action needed. If you want to use HS256, go to Supabase → Authentication → Configuration → JWT Settings → Algorithm → HS256 → Save. Existing sessions will be invalidated.

### 5. Create the Stripe webhook endpoint

1. Stripe dashboard → Developers → Webhooks → Add endpoint
2. URL: `https://flourish-proxy.<your-subdomain>.workers.dev/stripe/webhook`
3. Events to listen to:
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
4. Copy the **Signing secret** and set it via `wrangler secret put STRIPE_WEBHOOK_SECRET`

### 6. Deploy

```bash
cd cloudflare/
wrangler deploy
```

Wrangler prints the Worker URL (e.g. `https://flourish-proxy.yoursubdomain.workers.dev`). This is the value for `flourish_PROXY_URL` in `Secrets.xcconfig`.

---

## Change provider or model

1. Edit `ACTIVE_PROVIDER` and/or `ACTIVE_MODEL` in `cloudflare/wrangler.toml`
2. Run `wrangler deploy`

Takes effect immediately for all app instances on their next request. No app rebuild needed.

---

## Rotate a secret

```bash
cd cloudflare/
wrangler secret put <SECRET_NAME>
# Paste the new value when prompted
wrangler deploy
```

Rotating `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_JWT_SECRET` requires no app change. Rotating `STRIPE_SECRET_KEY` or `STRIPE_WEBHOOK_SECRET` requires no app change.

---

## Set up for local development (app side)

```bash
cp flourish/Config/Secrets.xcconfig.example flourish/Config/Secrets.xcconfig
```

Fill in (hostname only — no `https://`):

```
flourish_PROXY_URL = flourish-proxy.yoursubdomain.workers.dev
```

No static bearer token is required. The app authenticates to the Worker using the Supabase JWT obtained after sign-in.

Then:

```bash
make generate   # regenerate Xcode project
# build in Xcode
```

---

## View user data

All per-user data (plan, usage counters, Stripe customer IDs) is in Supabase → Table Editor → `user_subscriptions`.

To query from the CLI:

```bash
# Not needed — use Supabase dashboard instead
```

---

## Worker routes summary

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/improve` | POST | JWT | Forward prompt to LLM, check and increment usage |
| `/account/create` | POST | JWT | Idempotent upsert of user row (safety net) |
| `/account/usage` | GET | JWT | Return plan, usage count, limit, reset date |
| `/billing/checkout` | POST | JWT | Create Stripe Checkout Session |
| `/billing/portal` | GET | JWT | Create Stripe Billing Portal session |
| `/stripe/webhook` | POST | Stripe signature | Handle subscription and invoice events |

See [Worker API Reference](../reference/worker-api.md) for full request/response details.

---

## Related

- [Worker API Reference](../reference/worker-api.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [ADR-027: Supabase PostgreSQL over D1](../adr/027-supabase-postgres-over-d1.md)
- [ADR-028: ES256 JWT verification](../adr/028-es256-jwt-verification.md)
- [ADR-029: Supabase user lifecycle triggers](../adr/029-supabase-user-lifecycle-triggers.md)
- [ADR-026: Stripe billing via Worker](../adr/026-stripe-billing-via-worker.md)
- [Build Configuration Reference](../reference/build-configuration.md)
