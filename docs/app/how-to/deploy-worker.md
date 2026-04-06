# Deploy or Update the Cloudflare Worker

How to deploy the Flourish LLM proxy Worker for the first time, change the active provider or model, rotate the proxy bearer token, and set up a local development environment.

This guide is for founders and developers with access to the Cloudflare account. End users have no interaction with the Worker.

---

## Prerequisites

- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) installed: `npm install -g wrangler`
- Authenticated to the Cloudflare account: `wrangler login`
- Access to the project's `cloudflare/` directory

---

## First-time deployment

### 1. Configure provider and model

Edit `cloudflare/wrangler.toml` and set the plain-text environment variables:

```toml
[vars]
ACTIVE_PROVIDER = "openrouter"   # or "groq"
ACTIVE_MODEL    = "google/gemini-2.0-flash-001"
```

These are not secrets — they are visible in the Wrangler deploy output and the Cloudflare dashboard.

### 2. Set the provider API key as a secret

Secrets are encrypted and never appear in logs or the dashboard. Set them once:

```bash
cd cloudflare/
wrangler secret put OPENROUTER_API_KEY
# Paste the key when prompted

wrangler secret put GROQ_API_KEY
# Paste the key when prompted (if using Groq)
```

### 3. Set the proxy bearer token as a secret

The proxy bearer token is what the Flourish app uses to authenticate to the Worker. Generate a strong random token (e.g., `openssl rand -hex 32`) and store it:

```bash
wrangler secret put FLOURISH_PROXY_TOKEN
# Paste the token when prompted
```

Keep this token — you will need to embed it in `Secrets.xcconfig` for all development builds.

### 4. Deploy the Worker

```bash
cd cloudflare/
wrangler deploy
```

Wrangler prints the Worker's URL (e.g., `https://flourish-proxy.yoursubdomain.workers.dev`). Note this — it is the value for `FLOURISH_PROXY_URL` in `Secrets.xcconfig`.

---

## Change provider or model (no app rebuild required)

1. Edit `ACTIVE_PROVIDER` and/or `ACTIVE_MODEL` in `cloudflare/wrangler.toml`.
2. Run:

```bash
cd cloudflare/
wrangler deploy
```

The change takes effect immediately for all running app instances on their next request. No app rebuild or release is needed.

---

## Rotate the proxy bearer token

Rotating the token requires a new app build because the token is embedded in the binary via `Secrets.xcconfig` and `Info.plist`.

1. Generate a new token: `openssl rand -hex 32`
2. Update the secret in Cloudflare:

```bash
cd cloudflare/
wrangler secret put FLOURISH_PROXY_TOKEN
# Paste the new token
```

3. Update `FLOURISH_PROXY_TOKEN` in `Secrets.xcconfig` on every developer machine.
4. Build and distribute a new app version.

---

## Set up for development (app side)

1. Copy the example secrets file:

```bash
cp Flourish/Config/Secrets.xcconfig.example Flourish/Config/Secrets.xcconfig
```

2. Fill in the values (hostname only — no `https://`):

```
FLOURISH_PROXY_URL   = flourish-proxy.yoursubdomain.workers.dev
FLOURISH_PROXY_TOKEN = <token from step 3 above>
```

3. Regenerate the Xcode project and build:

```bash
make generate
# then build in Xcode
```

`FlourishProxyService` reads `FlourishProxyURL` and `FlourishProxyToken` from `Bundle.main.infoDictionary` at runtime. If either is missing or empty, it throws `LLMError.missingConfiguration`.

---

## Worker request format

The app sends a `POST` request to `https://<FLOURISH_PROXY_URL>/improve`:

```
POST /improve HTTP/1.1
Authorization: Bearer <FLOURISH_PROXY_TOKEN>
Content-Type: application/json

{
  "text": "<original prompt>",
  "systemPrompt": "<assembled system prompt>"
}
```

The Worker forwards to the configured provider and returns:

```json
{
  "text": "<improved prompt>",
  "tokensIn": 142,
  "tokensOut": 87,
  "model": "google/gemini-2.0-flash-001"
}
```

---

## Related

- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [Build Configuration Reference](../reference/build-configuration.md) — Secrets.xcconfig setup
- [LLM Service API Reference](../reference/llm-service-api.md)
- [Platform Security Reference](../../platform/security.md)
