# ADR-015: Cloudflare Worker Proxy for LLM API Access

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Replace per-user API key management (OpenRouter, Groq keys stored in Keychain) with a company-operated Cloudflare Worker that proxies all LLM requests. The app embeds only a single proxy bearer token; real provider API keys never leave the Worker's secret store.

---

## Context

The original architecture (ADR-005, ADR-006) required every user to:
1. Create their own OpenRouter or Groq account.
2. Generate an API key.
3. Enter that key into flourish's Settings → Providers UI.
4. Manage key rotation and account balance independently.

This created significant friction during onboarding and made it impossible for founders to iterate on provider or model selection without shipping an app update. It also meant that provider costs were distributed across many small accounts with no central visibility.

The business decision was made to absorb API costs centrally (charged per-seat or bundled) and remove all provider-facing complexity from the end user experience.

---

## Alternatives Considered

### Keep per-user API keys
Low infrastructure cost, but high user friction. Users must understand the concept of an API key, create accounts with two separate services, and manage billing. Rejected for product reasons.

### Embed API keys directly in the app binary
Zero infrastructure. However, keys would be trivially extractable from the binary using `strings` or a disassembler. Any key in a distributed binary must be considered compromised. Rejected on security grounds.

### Backend server (custom)
A self-hosted API gateway would give full control but requires running and maintaining infrastructure (servers, TLS certificates, authentication middleware, database for per-user rate limiting). Rejected as disproportionate for the current stage.

### Cloudflare Worker proxy
A lightweight JavaScript Worker deployed to Cloudflare's edge network. Real provider API keys are stored as Cloudflare secrets — they never appear in the Worker source code or in `wrangler.toml`. The app authenticates to the Worker with a single shared bearer token (`flourish_PROXY_TOKEN`). Provider and model selection are controlled by the founders via `ACTIVE_PROVIDER` and `ACTIVE_MODEL` environment variables in `wrangler.toml`. Changing provider or model requires only `wrangler deploy` — no app rebuild. Accepted.

---

## Decision Rationale

The Worker proxy achieves the product goal (zero API key friction for users) while satisfying the security constraint (no provider keys in the binary). Cloudflare Workers have:
- Sub-millisecond cold starts globally.
- Built-in secret storage (`wrangler secret put`) that is never exposed in logs or the dashboard.
- No server infrastructure to maintain.
- Free tier sufficient for early-stage usage.

The proxy bearer token (`flourish_PROXY_TOKEN`) is a lower-stakes secret than provider API keys: it is specific to this proxy, rate-limited by the Worker, and can be rotated independently of any provider account. It is stored in `Secrets.xcconfig` (gitignored) and injected into `Info.plist` at build time — it is never hardcoded in source.

The `//`-as-comment limitation of xcconfig syntax requires storing only the hostname in `Secrets.xcconfig` (e.g., `flourish-proxy.yoursubdomain.workers.dev`); the Swift code prepends `https://` when constructing the `URLRequest`.

---

## Architecture

```
flourish.app
    │  flourishProxyService (LLMService conformance)
    │  reads flourish_PROXY_URL + flourish_PROXY_TOKEN from Info.plist
    │
    ▼ HTTPS POST /improve
Cloudflare Worker (cloudflare/worker.js)
    │  validates Authorization: Bearer <flourish_PROXY_TOKEN>
    │  reads ACTIVE_PROVIDER + ACTIVE_MODEL from environment
    │  reads OPENROUTER_API_KEY or GROQ_API_KEY from Cloudflare secrets
    │
    ▼ HTTPS POST
Provider API (OpenRouter or Groq)
```

### Key files

| File | Purpose |
|------|---------|
| `cloudflare/worker.js` | The Worker script. Never committed with real API keys |
| `cloudflare/wrangler.toml` | Deploy config. `ACTIVE_PROVIDER` and `ACTIVE_MODEL` set here |
| `flourish/Core/Services/flourishProxyService.swift` | `LLMService` conformance. Reads proxy config from `Bundle.main.infoDictionary` |
| `flourish/Config/Secrets.xcconfig` | Gitignored. `flourish_PROXY_URL` (hostname only) and `flourish_PROXY_TOKEN` |
| `flourish/Config/Secrets.xcconfig.example` | Committed template. Safe to commit — contains no real values |

### Secrets.xcconfig syntax note

xcconfig files treat `//` as a line comment. URLs stored in xcconfig must omit the `https://` scheme. Only the hostname is stored:

```
flourish_PROXY_URL = flourish-proxy.yoursubdomain.workers.dev
flourish_PROXY_TOKEN = your-bearer-token-here
```

`flourishProxyService` prepends `https://` when constructing the request URL.

---

## Consequences

- Users no longer need API keys, provider accounts, or billing setup. ✓
- Provider and model can be changed without an app update. ✓
- Real API keys are never in the app binary or source repository. ✓
- `KeychainService`, `OpenRouterService`, `GroqService`, `ProviderPickerView`, `ProvidersTab`, and all `AppSettings` provider keys are removed. ✓
- All provider/model settings UI is removed from the app. ✓
- The app now has a single external dependency for LLM functionality (the Cloudflare Worker). If the Worker is unreachable, the app cannot improve prompts. This is a known and accepted trade-off.
- Token counts and cost estimates in `LLMResponse` still work as before — the Worker forwards the provider's usage object.
- The proxy bearer token (`flourish_PROXY_TOKEN`) must be protected. Rotation requires a new build (to embed the new token), but does not require changing provider accounts.

---

## Switching Provider or Model (Founders Only)

1. Edit `ACTIVE_PROVIDER` and `ACTIVE_MODEL` in `cloudflare/wrangler.toml`.
2. Run `wrangler deploy` from the `cloudflare/` directory.
3. No app rebuild or release required.

---

## Related

- [ADR-005: Keychain for API Keys](005-keychain-for-api-keys.md) — superseded by this ADR
- [ADR-006: LLM Service Protocol](006-llm-service-protocol.md) — protocol retained; implementations changed
- [LLM Service API Reference](../reference/llm-service-api.md)
- [Build Configuration Reference](../reference/build-configuration.md) — Secrets.xcconfig setup
- [Platform Security Reference](../../platform/security.md)
- [How-To: Deploy or Update the Worker](../how-to/deploy-worker.md)
