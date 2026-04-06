# Configure the LLM Provider and Model

How founders control which LLM provider and model the Flourish app uses, via the Cloudflare Worker proxy.

This guide is for founders and developers only. End users have no provider or model settings — the app connects to the proxy automatically.

---

## How provider and model selection works

Flourish sends all prompts to a Cloudflare Worker proxy (`cloudflare/worker.js`). The Worker holds the real provider API keys as Cloudflare secrets. Provider and model are controlled by two environment variables in `cloudflare/wrangler.toml`:

| Variable | Purpose | Example value |
|----------|---------|---------------|
| `ACTIVE_PROVIDER` | Which LLM provider the Worker routes to | `"openrouter"` or `"groq"` |
| `ACTIVE_MODEL` | The model ID forwarded to the provider | `"google/gemini-2.0-flash-001"` |

Changing either variable takes effect on the next `wrangler deploy`. No app rebuild is required.

---

## Change the active provider or model

1. Open `cloudflare/wrangler.toml`.
2. Edit `ACTIVE_PROVIDER` and/or `ACTIVE_MODEL` under `[vars]`:

```toml
[vars]
ACTIVE_PROVIDER = "openrouter"
ACTIVE_MODEL    = "google/gemini-2.0-flash-001"
```

3. Deploy:

```bash
cd cloudflare/
wrangler deploy
```

The change is live immediately.

---

## Update a provider API key

Provider API keys are stored as Cloudflare secrets — they are never in `wrangler.toml` or the Worker source. To update a key:

```bash
cd cloudflare/
wrangler secret put OPENROUTER_API_KEY
# or
wrangler secret put GROQ_API_KEY
```

Paste the new key when prompted. The secret is updated without redeploying.

---

## Related

- [How-To: Deploy or Update the Worker](deploy-worker.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [LLM Service API Reference](../reference/llm-service-api.md)
