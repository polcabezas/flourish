# ADR-023: Supabase Auth as the authentication provider

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use Supabase Auth for all authentication: email/password sign-in, Google OAuth, session management, and access tokens. The `AuthService` singleton wraps a `SupabaseClient` and exposes auth state to the app via the `authStateChanges` async stream as the single source of truth.

The Keychain service name is hardcoded to `"flourish"` (not the Supabase project name or URL domain).

---

## Context

flourish transitioned from a purely local app (no accounts) to an account-gated, usage-tracked product. Authentication became a requirement when billing and per-user request limits were introduced.

The app needed:
- Email/password sign-in and sign-up
- Google OAuth
- Secure token storage on macOS
- A way to feed JWT access tokens to the Cloudflare Worker for per-user authentication (see ADR-024)

---

## Alternatives Considered

### A. Custom auth: JWT minting in the Worker, credentials stored in Keychain

Rejected. Building a secure custom auth system — secure password hashing, token refresh, OAuth flows, email verification — from scratch inside a Cloudflare Worker is substantial scope with high security risk. Supabase provides all of this with a maintained client library.

### B. Sign in with Apple only

Rejected. Sign in with Apple requires App Sandbox and notarization (see ADR-008). flourish uses ad-hoc signing and no sandbox because it needs `CGEvent` access and `NSWorkspace` app activation. SiWA is not available without a paid Apple Developer account and notarization pipeline that would need to be built separately. Google OAuth + email/password covers the target audience without those constraints.

### C. Firebase Auth

Considered. Firebase Auth is a direct competitor to Supabase Auth. Supabase was chosen because:
- The `supabase-swift` v2 SDK handles `authStateChanges` as a typed async stream, integrating cleanly with Swift concurrency
- Supabase is already used for Keychain storage via `KeychainLocalStorage`, providing one vendor for both auth and Keychain abstraction
- Supabase's self-hosted option is available if vendor lock-in becomes a concern in the future

### D. Supabase Auth (chosen)

`SupabaseClient` is instantiated once in `AuthService.shared`. The `authStateChanges` stream emits an `(AuthChangeEvent, Session?)` tuple on every state transition (signed in, signed out, token refreshed). `AppDelegate` starts observing this stream on launch and drives UI gating from it — no polling, no manual token refresh.

---

## authStateChanges as single source of truth

The key architectural consequence is that **no other part of the app reads auth state directly**. All consumers — `AppDelegate`, `MenuBarManager`, `flourishProxyService` — query `AuthService.shared`, which caches the current session from the stream.

This means:
- Token refresh (handled automatically by the Supabase SDK) is transparent to the rest of the app
- Sign-out from any trigger (user action, remote invalidation) propagates immediately to all observers via the single stream

---

## Keychain service name: "flourish"

The `supabase-swift` SDK stores session tokens in the system Keychain via `KeychainLocalStorage`. The service name passed to `KeychainLocalStorage(service:accessGroup:)` determines the Keychain item label visible in Keychain Access.

Using `"flourish"` instead of the Supabase project name or URL domain:
- Keeps the implementation detail (Supabase) hidden from the Keychain entry label
- Provides a stable name that does not change if the Supabase project is renamed or migrated
- Matches the app's brand in Keychain Access

---

## Consequences

- Google OAuth uses the custom URL scheme `flourish://auth/callback`. `AppDelegate` handles incoming URLs via `application(_:open:)` and calls `AuthService.shared.handleAuthCallback(url:)`. The custom scheme is registered in `Info.plist`.
- Accessibility permission request is deferred to post-login (see ADR-024). It is not requested on cold launch — only after `AuthService` emits a signed-in state.
- `AuthService.shared.currentAccessToken()` is `async` because it may trigger a silent token refresh. `flourishProxyService` must `await` it before each request (replaces the static proxy token from ADR-015).
- The `lastKnownSubscription` Defaults key caches the plan tier locally to avoid a usage API call on every launch.

---

## Related

- [ADR-015: Cloudflare Worker Proxy](015-cloudflare-worker-proxy.md)
- [ADR-024: Auth-gated UI](024-auth-gated-ui.md)
- [ADR-025: Cloudflare D1 usage tracking](025-cloudflare-d1-usage-tracking.md)
- [ADR-026: Stripe billing via Worker](026-stripe-billing-via-worker.md)
- [App Settings Reference](../reference/app-settings.md)
