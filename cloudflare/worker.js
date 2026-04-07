/**
 * flourish Proxy Worker
 *
 * Sits between the flourish macOS app and LLM providers.
 * Auth:    Supabase JWT (HS256) validated against SUPABASE_JWT_SECRET.
 * Storage: Supabase PostgreSQL via REST API (replaces Cloudflare D1).
 * Billing: Stripe.
 *
 * Required secrets (wrangler secret put):
 *   SUPABASE_JWT_SECRET       — Supabase Project Settings → API → JWT Secret
 *   SUPABASE_SERVICE_ROLE_KEY — Supabase Project Settings → API → service_role key
 *   OPENROUTER_API_KEY
 *   GROQ_API_KEY
 *   STRIPE_SECRET_KEY         — sk_test_… or sk_live_…
 *   STRIPE_WEBHOOK_SECRET     — from Stripe dashboard after creating webhook
 *   STRIPE_PRO_PRICE_ID_MONTHLY
 *   STRIPE_PRO_PRICE_ID_YEARLY
 *
 * Plain vars (wrangler.toml [vars]):
 *   SUPABASE_URL    — e.g. "https://xyzabc.supabase.co"
 *   ACTIVE_PROVIDER — "openrouter" | "groq"
 *   ACTIVE_MODEL    — e.g. "llama-3.1-8b-instant"
 */

const PLAN_LIMITS = { free: 30, pro: null }; // null = unlimited

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;
    const method = request.method;

    if (method === "OPTIONS")
      return new Response(null, { status: 204, headers: corsHeaders() });

    try {
      if (pathname === "/improve"         && method === "POST") return withCors(await handleImprove(request, env));
      if (pathname === "/account/create"  && method === "POST") return withCors(await handleAccountCreate(request, env));
      if (pathname === "/account/usage"   && method === "GET")  return withCors(await handleAccountUsage(request, env));
      if (pathname === "/billing/checkout"&& method === "POST") return withCors(await handleBillingCheckout(request, env));
      if (pathname === "/billing/portal"  && method === "GET")  return withCors(await handleBillingPortal(request, env));
      if (pathname === "/stripe/webhook"  && method === "POST") return withCors(await handleStripeWebhook(request, env));
      return new Response("Not Found", { status: 404 });
    } catch (err) {
      console.error("Unhandled error:", err);
      return withCors(new Response("Internal Server Error", { status: 500 }));
    }
  },
};

// ---------------------------------------------------------------------------
// POST /improve
// ---------------------------------------------------------------------------

async function handleImprove(request, env) {
  const claims = await requireAuth(request, env);
  if (claims instanceof Response) return claims;

  const userId = claims.sub;
  const email  = claims.email ?? "";

  await ensureUserRow(env, userId, email);

  let row = await getUserRow(env, userId);
  row = await maybeResetMonth(env, userId, row);

  const limit = row.subscription in PLAN_LIMITS ? PLAN_LIMITS[row.subscription] : PLAN_LIMITS.free;
  if (limit !== null && row.requests_this_month >= limit)
    return json({ error: "monthly_limit_reached", plan: row.subscription, limit }, 429);

  let body;
  try { body = await request.json(); }
  catch { return new Response("Bad Request: invalid JSON", { status: 400 }); }

  if (!Array.isArray(body.messages) || body.messages.length === 0)
    return new Response("Bad Request: messages array required", { status: 400 });

  const llmResponse = await forwardToLLM(body.messages, env);

  if (llmResponse.status === 200)
    await incrementRequests(env, userId);

  return llmResponse;
}

// ---------------------------------------------------------------------------
// POST /account/create
// ---------------------------------------------------------------------------

async function handleAccountCreate(request, env) {
  const claims = await requireAuth(request, env);
  if (claims instanceof Response) return claims;

  await ensureUserRow(env, claims.sub, claims.email ?? "");
  const row = await getUserRow(env, claims.sub);
  return json(row);
}

// ---------------------------------------------------------------------------
// GET /account/usage
// ---------------------------------------------------------------------------

async function handleAccountUsage(request, env) {
  const claims = await requireAuth(request, env);
  if (claims instanceof Response) return claims;

  let row = await getUserRow(env, claims.sub);
  if (!row) return new Response("Not Found", { status: 404 });
  row = await maybeResetMonth(env, claims.sub, row);

  const limit = row.subscription in PLAN_LIMITS ? PLAN_LIMITS[row.subscription] : PLAN_LIMITS.free;
  return json({
    plan: row.subscription,
    requests_this_month: row.requests_this_month,
    limit,
    reset_at: row.reset_at,
  });
}

// ---------------------------------------------------------------------------
// POST /billing/checkout
// ---------------------------------------------------------------------------

async function handleBillingCheckout(request, env) {
  const claims = await requireAuth(request, env);
  if (claims instanceof Response) return claims;

  let row = await getUserRow(env, claims.sub);
  if (!row)
    return new Response("Account not found. Call /account/create first.", { status: 404 });

  // Lazily create Stripe customer
  if (!row.stripe_customer_id) {
    const customerResp = await fetch("https://api.stripe.com/v1/customers", {
      method: "POST",
      headers: stripeHeaders(env),
      body: new URLSearchParams({
        email: row.email,
        "metadata[flourish_user_id]": claims.sub,
      }),
    });
    const customer = await customerResp.json();
    if (!customer.id)
      return new Response("Failed to create billing account.", { status: 502 });

    await sbPatch(env, `user_subscriptions?user_id=eq.${encodeURIComponent(claims.sub)}`,
      { stripe_customer_id: customer.id });
    row = { ...row, stripe_customer_id: customer.id };
  }

  let body;
  try { body = await request.json(); } catch { body = {}; }

  const successUrl   = body.success_url ?? "https://flourish.app/billing/success";
  const cancelUrl    = body.cancel_url  ?? "https://flourish.app/billing/cancel";
  const billingPeriod = body.billing_period === "yearly" ? "yearly" : "monthly";
  const priceId = billingPeriod === "yearly"
    ? env.STRIPE_PRO_PRICE_ID_YEARLY
    : env.STRIPE_PRO_PRICE_ID_MONTHLY;

  const sessionResp = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: stripeHeaders(env),
    body: new URLSearchParams({
      customer: row.stripe_customer_id,
      mode: "subscription",
      "line_items[0][price]": priceId,
      "line_items[0][quantity]": "1",
      success_url: successUrl,
      cancel_url:  cancelUrl,
    }),
  });
  const session = await sessionResp.json();
  if (!session.url)
    return new Response("Failed to create checkout session.", { status: 502 });

  return json({ url: session.url });
}

// ---------------------------------------------------------------------------
// GET /billing/portal
// ---------------------------------------------------------------------------

async function handleBillingPortal(request, env) {
  const claims = await requireAuth(request, env);
  if (claims instanceof Response) return claims;

  const row = await getUserRow(env, claims.sub);
  if (!row?.stripe_customer_id)
    return new Response("No billing account found. Upgrade first.", { status: 404 });

  const portalResp = await fetch("https://api.stripe.com/v1/billing_portal/sessions", {
    method: "POST",
    headers: stripeHeaders(env),
    body: new URLSearchParams({ customer: row.stripe_customer_id }),
  });
  const portal = await portalResp.json();
  if (!portal.url)
    return new Response("Failed to create portal session.", { status: 502 });

  return json({ url: portal.url });
}

// ---------------------------------------------------------------------------
// POST /stripe/webhook
// ---------------------------------------------------------------------------

async function handleStripeWebhook(request, env) {
  const payload   = await request.text();
  const signature = request.headers.get("stripe-signature") ?? "";

  const valid = await verifyStripeSignature(payload, signature, env.STRIPE_WEBHOOK_SECRET);
  if (!valid) return new Response("Invalid signature", { status: 400 });

  const event = JSON.parse(payload);

  if (event.type === "customer.subscription.updated" ||
      event.type === "customer.subscription.deleted") {
    const sub        = event.data.object;
    const customerId = sub.customer;
    const newPlan    = sub.status === "active" ? "pro" : "free";
    await sbPatch(env, `user_subscriptions?stripe_customer_id=eq.${encodeURIComponent(customerId)}`,
      { subscription: newPlan });
  }

  if (event.type === "invoice.paid") {
    const customerId = event.data.object.customer;
    const thisMonth  = currentMonthStart();
    await sbPatch(env, `user_subscriptions?stripe_customer_id=eq.${encodeURIComponent(customerId)}`,
      { requests_this_month: 0, reset_at: thisMonth });
  }

  return new Response("OK", { status: 200 });
}

// ---------------------------------------------------------------------------
// LLM Forwarding
// ---------------------------------------------------------------------------

async function forwardToLLM(messages, env) {
  const provider = env.ACTIVE_PROVIDER ?? "groq";
  const model    = env.ACTIVE_MODEL    ?? "llama-3.1-8b-instant";

  let upstreamURL, apiKey;
  const extraHeaders = {};

  if (provider === "groq") {
    upstreamURL = "https://api.groq.com/openai/v1/chat/completions";
    apiKey = env.GROQ_API_KEY;
  } else {
    upstreamURL = "https://openrouter.ai/api/v1/chat/completions";
    apiKey = env.OPENROUTER_API_KEY;
    extraHeaders["HTTP-Referer"] = "com.personal.flourish";
    extraHeaders["X-Title"]      = "flourish";
  }

  let upstreamResponse;
  try {
    upstreamResponse = await fetch(upstreamURL, {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json", ...extraHeaders },
      body: JSON.stringify({ model, stream: false, messages }),
    });
  } catch (err) {
    return new Response(`Upstream request failed: ${err.message}`, { status: 502 });
  }

  const responseBody = await upstreamResponse.text();
  return new Response(responseBody, {
    status: upstreamResponse.status,
    headers: { "Content-Type": "application/json", "X-flourish-Provider": provider },
  });
}

// ---------------------------------------------------------------------------
// Supabase REST API helpers
// ---------------------------------------------------------------------------

function sbHeaders(env) {
  return {
    "apikey":        env.SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    "Content-Type":  "application/json",
  };
}

function sbURL(env, path) {
  const base = (env.SUPABASE_URL ?? "").replace(/\/$/, "");
  return `${base}/rest/v1/${path}`;
}

async function getUserRow(env, userId) {
  const resp = await fetch(
    sbURL(env, `user_subscriptions?user_id=eq.${encodeURIComponent(userId)}&select=*`),
    { headers: sbHeaders(env) },
  );
  const rows = await resp.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function ensureUserRow(env, userId, email) {
  await fetch(sbURL(env, "user_subscriptions"), {
    method: "POST",
    headers: { ...sbHeaders(env), "Prefer": "resolution=ignore-duplicates" },
    body: JSON.stringify({
      user_id: userId,
      email,
      subscription: "free",
      requests_this_month: 0,
      reset_at: currentMonthStart(),
    }),
  });
}

async function sbPatch(env, path, body) {
  await fetch(sbURL(env, path), {
    method: "PATCH",
    headers: sbHeaders(env),
    body: JSON.stringify(body),
  });
}

async function incrementRequests(env, userId) {
  // Uses a Postgres function to avoid race conditions on concurrent requests.
  await fetch(sbURL(env, "rpc/increment_user_requests"), {
    method: "POST",
    headers: sbHeaders(env),
    body: JSON.stringify({ p_user_id: userId }),
  });
}

async function maybeResetMonth(env, userId, row) {
  const thisMonth = currentMonthStart();
  if (row.reset_at < thisMonth) {
    await sbPatch(env, `user_subscriptions?user_id=eq.${encodeURIComponent(userId)}`,
      { requests_this_month: 0, reset_at: thisMonth });
    return { ...row, requests_this_month: 0, reset_at: thisMonth };
  }
  return row;
}

// ---------------------------------------------------------------------------
// JWT Validation — supports HS256 (legacy) and ES256 (current Supabase default)
//
// ES256: public key is fetched once from Supabase JWKS and cached for the
//        lifetime of the worker isolate (SUPABASE_URL plain var required).
// HS256: verified against SUPABASE_JWT_SECRET as before.
// ---------------------------------------------------------------------------

let _cachedEs256Key = null;

async function getEs256Key(env) {
  if (_cachedEs256Key) return _cachedEs256Key;
  const base = (env.SUPABASE_URL ?? "").replace(/\/$/, "");
  if (!base) return null;
  try {
    const resp = await fetch(`${base}/auth/v1/.well-known/jwks.json`);
    if (!resp.ok) return null;
    const { keys } = await resp.json();
    const jwk = keys.find(k => k.alg === "ES256" || k.crv === "P-256");
    if (!jwk) return null;
    _cachedEs256Key = await crypto.subtle.importKey(
      "jwk", jwk, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"],
    );
    return _cachedEs256Key;
  } catch { return null; }
}

async function verifySupabaseJWT(token, env) {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [headerB64, payloadB64, sigB64] = parts;

  let header;
  try {
    header = JSON.parse(atob(headerB64.replace(/-/g, "+").replace(/_/g, "/")));
  } catch { return null; }

  const alg        = header.alg ?? "HS256";
  const encoder    = new TextEncoder();
  const sigBytes   = base64UrlDecode(sigB64);
  const signedData = encoder.encode(`${headerB64}.${payloadB64}`);

  let valid = false;
  try {
    if (alg === "ES256") {
      const key = await getEs256Key(env);
      if (!key) return null;
      valid = await crypto.subtle.verify(
        { name: "ECDSA", hash: "SHA-256" }, key, sigBytes, signedData,
      );
    } else {
      const key = await crypto.subtle.importKey(
        "raw", encoder.encode(env.SUPABASE_JWT_SECRET),
        { name: "HMAC", hash: "SHA-256" }, false, ["verify"],
      );
      valid = await crypto.subtle.verify("HMAC", key, sigBytes, signedData);
    }
  } catch { return null; }

  if (!valid) return null;

  let payload;
  try {
    payload = JSON.parse(atob(payloadB64.replace(/-/g, "+").replace(/_/g, "/")));
  } catch { return null; }

  if (payload.exp < Math.floor(Date.now() / 1000)) return null;
  return payload;
}

async function requireAuth(request, env) {
  const authHeader = request.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) return new Response("Unauthorized", { status: 401 });

  const claims = await verifySupabaseJWT(token, env);
  if (!claims) return new Response("Unauthorized", { status: 401 });
  return claims;
}

// ---------------------------------------------------------------------------
// Stripe Signature Verification
// ---------------------------------------------------------------------------

async function verifyStripeSignature(payload, header, secret) {
  const parts     = Object.fromEntries(header.split(",").map(p => p.split("=")));
  const timestamp = parts["t"];
  const expected  = parts["v1"];
  if (!timestamp || !expected) return false;

  const encoder = new TextEncoder();
  let key;
  try {
    key = await crypto.subtle.importKey(
      "raw", encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
    );
  } catch { return false; }

  const sig      = await crypto.subtle.sign("HMAC", key, encoder.encode(`${timestamp}.${payload}`));
  const computed = Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, "0")).join("");
  return computed === expected;
}

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

function currentMonthStart() {
  const now = new Date();
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}-01`;
}

function base64UrlDecode(str) {
  const b64    = str.replace(/-/g, "+").replace(/_/g, "/");
  const padded = b64.padEnd(b64.length + ((4 - (b64.length % 4)) % 4), "=");
  return Uint8Array.from(atob(padded), c => c.charCodeAt(0));
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}

function withCors(response) {
  const headers = new Headers(response.headers);
  Object.entries(corsHeaders()).forEach(([k, v]) => headers.set(k, v));
  return new Response(response.body, { status: response.status, headers });
}

function stripeHeaders(env) {
  return {
    Authorization:  `Bearer ${env.STRIPE_SECRET_KEY}`,
    "Content-Type": "application/x-www-form-urlencoded",
  };
}
