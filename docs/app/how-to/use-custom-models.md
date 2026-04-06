# Change the Active Model

How to change which LLM model Flourish uses. This is a founder/developer operation performed via the Cloudflare Worker — there is no model selector in the app UI.

---

## Overview

The active model is set in `cloudflare/wrangler.toml` and applied by running `wrangler deploy`. End users always use whichever model is currently active in the Worker — they cannot change it from the app.

---

## Steps

1. Open `cloudflare/wrangler.toml`.
2. Set `ACTIVE_MODEL` to the model ID you want to use:

```toml
[vars]
ACTIVE_PROVIDER = "openrouter"
ACTIVE_MODEL    = "anthropic/claude-3.5-sonnet"
```

3. Deploy the change:

```bash
cd cloudflare/
wrangler deploy
```

The new model is active immediately. No app rebuild required.

---

## Choosing a model ID

The model ID must match what the active provider's API expects.

### OpenRouter model IDs

Browse models at [openrouter.ai/models](https://openrouter.ai/models). IDs use the format `provider/model-name`, e.g.:
- `google/gemini-2.0-flash-001`
- `anthropic/claude-3.5-sonnet`
- `openai/gpt-4o-mini`

### Groq model IDs

Browse models at [console.groq.com/docs/models](https://console.groq.com/docs/models). IDs are simple strings, e.g.:
- `llama-3.3-70b-versatile`
- `llama-3.1-8b-instant`

---

## Related

- [How-To: Deploy or Update the Worker](deploy-worker.md)
- [How-To: Configure the LLM Provider](configure-providers.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
