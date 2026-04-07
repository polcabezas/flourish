# How flourish Connects to an LLM

**Note:** This document replaces the former "Add Your First Provider" tutorial. As of the current architecture, flourish connects to LLM providers automatically via a company-operated Cloudflare Worker proxy. Users do not configure API keys or select providers. This page explains the connection model for developers building from source.

---

## What changed

Previously, users had to create accounts with OpenRouter or Groq, generate API keys, and enter them in Settings. This is no longer required.

The app now authenticates to a Cloudflare Worker proxy using a single bearer token embedded at build time. The Worker holds the real provider API keys and routes requests to the configured provider.

---

## For developers building from source

To make LLM requests work when building locally, you need the proxy credentials embedded in `Secrets.xcconfig`. These come from the team (whoever manages the Cloudflare account).

Follow the steps in [Getting Started](getting-started.md) — specifically the `Secrets.xcconfig` setup in Step 2.

---

## For founders: changing the provider or model

See [How-To: Configure the LLM Provider](../how-to/configure-providers.md).

---

## Try the overlay

Once the app is built with valid credentials:

1. Press **Ctrl+Space** to open the overlay.
2. Type: `i need help writing thing for work`
3. Press **Return**.
4. The improved prompt is pasted back.

---

## Next Steps

- [Create a Custom Profile](create-custom-profile.md) — control how the AI rewrites your prompts
- [How-To: Deploy or Update the Worker](../how-to/deploy-worker.md) — manage the proxy (founders)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md) — architectural rationale
