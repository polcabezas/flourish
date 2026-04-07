# Add Support for a New LLM Provider

How to extend the Cloudflare Worker proxy to route to a new LLM provider, and update `flourishProxyService` if the new provider requires a non-standard request format.

---

## Overview

With the proxy architecture (ADR-015), adding a new provider is primarily a Worker-side change. The app itself (`flourishProxyService`) sends a fixed request format to the Worker and receives a fixed response format — it does not know which provider the Worker talks to.

Most additions require no app changes at all.

---

## Step 1 — Add the provider API key as a Cloudflare secret

```bash
cd cloudflare/
wrangler secret put NEW_PROVIDER_API_KEY
# Paste the key when prompted
```

---

## Step 2 — Update `cloudflare/worker.js`

Add a routing branch for the new provider. The Worker reads `ACTIVE_PROVIDER` from its environment and dispatches accordingly:

```javascript
// In worker.js, inside the routing switch:
case 'newprovider': {
  const url = 'https://api.newprovider.com/v1/chat/completions';
  const headers = {
    'Authorization': `Bearer ${env.NEW_PROVIDER_API_KEY}`,
    'Content-Type': 'application/json',
  };
  const body = JSON.stringify({
    model: env.ACTIVE_MODEL,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user',   content: text },
    ],
  });
  // Make the fetch, parse the response, return { text, tokensIn, tokensOut, model }
  break;
}
```

If the new provider uses an OpenAI-compatible API, you can reuse the existing `callOpenAICompatible(url, key, body, env)` helper already present in `worker.js`.

---

## Step 3 — Switch to the new provider

In `cloudflare/wrangler.toml`:

```toml
[vars]
ACTIVE_PROVIDER = "newprovider"
ACTIVE_MODEL    = "newprovider-model-id"
```

Deploy:

```bash
wrangler deploy
```

---

## When an app change is also needed

The app needs updating only if the new provider's response format cannot be normalized into the existing `{ text, tokensIn, tokensOut, model }` Worker response shape. In practice this is rare — the Worker handles normalization.

If you do need to change the Worker response shape, update `flourishProxyService.swift` to decode the new fields, and update `LLMResponse` in `Core/Services/LLMService.swift` accordingly.

---

## Related

- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [ADR-006: LLM Service Protocol](../adr/006-llm-service-protocol.md)
- [How-To: Deploy or Update the Worker](deploy-worker.md)
- [LLM Service API Reference](../reference/llm-service-api.md)
- [LLM Provider Abstraction Explanation](../explanation/llm-provider-abstraction.md)
