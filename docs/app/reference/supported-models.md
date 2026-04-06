# Supported Models Reference

All built-in LLM models in Flourish, with identifiers and pricing. Custom model IDs can be entered for any model not in this list.

---

## OpenRouter Models

Accessed via `https://openrouter.ai/api/v1/chat/completions`. Pricing is per million tokens (USD).

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

---

## Groq Models

Accessed via `https://api.groq.com/openai/v1/chat/completions`. All free on the standard tier (subject to rate limits).

| Display Name | Model ID | Speed | Notes |
|-------------|----------|-------|-------|
| Llama 3.3 70B Versatile | `llama-3.3-70b-versatile` | Fast | Best quality on Groq. Recommended default |
| Llama 3.1 70B Versatile | `llama-3.1-70b-versatile` | Fast | Older but stable |
| Llama 3.1 8B Instant | `llama-3.1-8b-instant` | Fastest | Best for very short prompts |
| Llama 3 70B | `llama3-70b-8192` | Fast | Solid general-purpose |
| Mixtral 8x7B | `mixtral-8x7b-32768` | Fast | MoE architecture, good context window |
| Gemma 2 9B | `gemma2-9b-it` | Fast | Google's compact model |

Groq pricing in Flourish: `pricePerMTokenIn = 0`, `pricePerMTokenOut = 0`. Cost estimate always shows $0.00 for Groq models.

---

## Using Custom Models

Any model ID available on OpenRouter or Groq can be entered as a custom model. See [Use Custom Models](../how-to/use-custom-models.md).

---

## Model Selection Persistence

| Provider | Defaults Key | Default Value |
|----------|-------------|---------------|
| OpenRouter | `openRouterModel` | `"google/gemini-2.0-flash-001"` |
| Groq | `groqModel` | `"llama-3.3-70b-versatile"` |

---

## Cost Calculation

For each LLM response, Flourish calculates:

```
cost = (tokensIn  / 1_000_000) × pricePerMTokenIn
     + (tokensOut / 1_000_000) × pricePerMTokenOut
```

This value is stored in `history_entry.estimated_cost_usd` and accumulated in `Defaults[.totalCostUSD]`.

Note: Pricing is set at release time. OpenRouter adjusts model pricing periodically. The displayed costs may not reflect current pricing.

---

## Related

- [Data Models Reference](data-models.md) — `ModelOption` struct with full pricing
- [Configure Providers](../how-to/configure-providers.md)
- [Use Custom Models](../how-to/use-custom-models.md)
- [LLM Service API Reference](llm-service-api.md)
