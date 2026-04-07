# Supported Models Reference

The LLM model used by flourish is configured in the Cloudflare Worker via `ACTIVE_MODEL` in `cloudflare/wrangler.toml`. End users do not select models — this is a founder/developer operation.

This page lists commonly used models for reference when choosing a value for `ACTIVE_MODEL`.

---

## OpenRouter Models

Set `ACTIVE_PROVIDER = "openrouter"` and `ACTIVE_MODEL` to one of the IDs below. Pricing is per million tokens (USD).

| Display Name | Model ID | $/M tokens in | $/M tokens out | Notes |
|-------------|----------|--------------|----------------|-------|
| Gemini 2.0 Flash | `google/gemini-2.0-flash-001` | $0.10 | $0.40 | Fast, high quality. Recommended default |
| GPT-4o Mini | `openai/gpt-4o-mini` | $0.15 | $0.60 | Reliable, well-rounded |
| Gemini 1.5 Flash | `google/gemini-flash-1.5` | $0.075 | $0.30 | Cheapest OpenRouter option |
| Claude 3 Haiku | `anthropic/claude-3-haiku` | $0.25 | $1.25 | Excellent instruction-following |
| Llama 3.1 8B | `meta-llama/llama-3.1-8b-instruct` | $0.06 | $0.06 | Fastest, lowest cost |
| Llama 3.1 70B | `meta-llama/llama-3.1-70b-instruct` | $0.40 | $0.40 | Strong open-source quality |
| Mistral 7B | `mistralai/mistral-7b-instruct` | $0.07 | $0.07 | Efficient European open model |
| GPT-4o | `openai/gpt-4o` | $2.50 | $10.00 | Highest quality; expensive |
| Claude 3.5 Sonnet | `anthropic/claude-3.5-sonnet` | $3.00 | $15.00 | Best at nuanced rewriting; expensive |
| Qwen 2.5 72B | `qwen/qwen-2.5-72b-instruct` | $0.35 | $0.40 | Strong multilingual model |

For the full model list, see [openrouter.ai/models](https://openrouter.ai/models).

---

## Groq Models

Set `ACTIVE_PROVIDER = "groq"` and `ACTIVE_MODEL` to one of the IDs below.

| Display Name | Model ID | Speed | Notes |
|-------------|----------|-------|-------|
| Llama 3.3 70B Versatile | `llama-3.3-70b-versatile` | Fast | Best quality on Groq. Recommended default |
| Llama 3.1 70B Versatile | `llama-3.1-70b-versatile` | Fast | Older but stable |
| Llama 3.1 8B Instant | `llama-3.1-8b-instant` | Fastest | Best for very short prompts |
| Llama 3 70B | `llama3-70b-8192` | Fast | Solid general-purpose |
| Mixtral 8x7B | `mixtral-8x7b-32768` | Fast | MoE architecture, good context window |
| Gemma 2 9B | `gemma2-9b-it` | Fast | Google's compact model |

For the full model list, see [console.groq.com/docs/models](https://console.groq.com/docs/models).

---

## Cost Calculation

For each LLM response, flourish calculates:

```
cost = (tokensIn  / 1_000_000) × pricePerMTokenIn
     + (tokensOut / 1_000_000) × pricePerMTokenOut
```

The Worker returns token counts from the provider's usage object. The app calculates cost locally based on the `model` string returned in `LLMResponse`. If the model string does not match a known entry in `ModelOption`, cost defaults to `$0.00`.

Note: Pricing is set at build time. Providers adjust model pricing periodically. Displayed costs are estimates only.

---

## Changing the Active Model

See [How-To: Change the Active Model](../how-to/use-custom-models.md) for instructions on updating `wrangler.toml` and deploying.

---

## Related

- [How-To: Configure the LLM Provider](../how-to/configure-providers.md)
- [How-To: Deploy or Update the Worker](../how-to/deploy-worker.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [LLM Service API Reference](llm-service-api.md)
