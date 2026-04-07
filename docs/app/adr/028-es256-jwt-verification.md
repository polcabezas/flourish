# ADR-028: ES256 JWT verification with JWKS caching

**Status:** Accepted — extends [ADR-025](025-cloudflare-d1-usage-tracking.md) JWT section  
**Date:** 2026-04

---

## Decision

The Cloudflare Worker JWT verifier is extended to support both **HS256** (HMAC-SHA256, legacy Supabase projects) and **ES256** (ECDSA P-256, current Supabase default). The algorithm is detected from the JWT header `alg` field. For ES256, the public key is fetched once from the Supabase JWKS endpoint and cached at module level for the lifetime of the worker isolate.

---

## Context

ADR-025 documented JWT verification assuming HS256, where the Supabase JWT secret is used as an HMAC key. This is the algorithm Supabase used by default for projects created before mid-2024.

Supabase now defaults to **ES256** (ECDSA with P-256 curve) for new projects. ES256 is asymmetric: tokens are signed with Supabase's private key and verified with the corresponding public key. The public key is published at the Supabase JWKS endpoint:

```
https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json
```

The original Worker would return 401 for all ES256 tokens because `crypto.subtle.verify("HMAC", ...)` fails on an ECDSA signature — silently, without error, returning `false`. This caused every request from a new Supabase project to fail authentication with no visible indication that the algorithm mismatch was the cause.

The root cause was identified by decoding the JWT header: `eyJhbGciOiJFUzI1NiIs` → `{"alg":"ES256",...}`.

---

## Alternatives Considered

### A. Switch Supabase project to HS256

Supabase allows changing the JWT algorithm in Authentication → Configuration → JWT Settings. This would require invalidating all active sessions (users must sign in again) and re-deploying the Worker with the new secret. Rejected because: not all Supabase plans allow algorithm changes, and forcing users to re-authenticate is disruptive.

### B. Hardcode the ES256 public key as a Worker secret

The public key could be extracted from the JWKS endpoint once, stored as a `SUPABASE_JWT_PUBLIC_KEY` secret, and imported on every request. This removes the outbound JWKS fetch entirely. Not chosen because it requires a manual step each time the key rotates, and JWKS fetching with module-level caching achieves the same performance after the first request.

### C. Dynamic JWKS with module-level cache (chosen)

On the first request to a fresh worker isolate, the Worker fetches the JWKS endpoint and imports the EC public key via `crypto.subtle.importKey`. The imported `CryptoKey` object is stored in a module-level variable (`_cachedEs256Key`). Subsequent requests within the same isolate lifetime reuse the cached key at zero additional cost.

Cloudflare Worker isolates are long-lived under normal load. In practice, the JWKS fetch happens at most once per isolate warm-up, not once per request.

---

## Implementation

```javascript
let _cachedEs256Key = null;

async function getEs256Key(env) {
  if (_cachedEs256Key) return _cachedEs256Key;
  const base = (env.SUPABASE_URL ?? "").replace(/\/$/, "");
  const resp = await fetch(`${base}/auth/v1/.well-known/jwks.json`);
  if (!resp.ok) return null;
  const { keys } = await resp.json();
  const jwk = keys.find(k => k.alg === "ES256" || k.crv === "P-256");
  if (!jwk) return null;
  _cachedEs256Key = await crypto.subtle.importKey(
    "jwk", jwk, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"],
  );
  return _cachedEs256Key;
}
```

`verifySupabaseJWT` reads the `alg` field from the decoded JWT header and branches:

```javascript
if (alg === "ES256") {
  const key = await getEs256Key(env);
  valid = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" }, key, sigBytes, signedData,
  );
} else {
  // HS256 path (legacy)
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(env.SUPABASE_JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" }, false, ["verify"],
  );
  valid = await crypto.subtle.verify("HMAC", key, sigBytes, signedData);
}
```

Both paths perform the same expiry check (`payload.exp < Date.now() / 1000`) after signature verification.

---

## New environment variable

| Variable | Type | Purpose |
|----------|------|---------|
| `SUPABASE_URL` | plain var (`wrangler.toml`) | Base URL for JWKS fetch (e.g. `https://xyz.supabase.co`) |

`SUPABASE_JWT_SECRET` is retained as a fallback for HS256 projects. It is unused for ES256 tokens.

---

## Consequences

- The first `/improve` (or any authenticated) request after an isolate cold-start makes one outbound HTTPS fetch to `<supabase-project>/auth/v1/.well-known/jwks.json`. This adds ~50–100 ms of latency to that single request only. All subsequent requests use the cached key.
- If the JWKS fetch fails (Supabase unreachable), `getEs256Key` returns `null` and `verifySupabaseJWT` returns `null`, causing a 401. This is the safe failure mode — better than accepting unverified tokens.
- The Worker now supports both HS256 and ES256 simultaneously. Migrating a project to HS256 requires no Worker changes.
- Key rotation by Supabase requires an isolate restart to pick up the new public key. This happens automatically on the next Cloudflare deployment or isolate eviction.

---

## Related

- [ADR-025: Cloudflare D1 usage tracking](025-cloudflare-d1-usage-tracking.md)
- [ADR-027: Supabase PostgreSQL over D1](027-supabase-postgres-over-d1.md)
- [ADR-023: Supabase Auth strategy](023-supabase-auth-strategy.md)
