# Use Custom Models

How to enter an arbitrary model ID not present in Flourish's curated dropdown.

---

## When to use this

The built-in model lists cover the most popular models at the time of release. Use a custom model ID when:
- A new model was released after Flourish's list was frozen.
- You have access to a private or fine-tuned model on OpenRouter.
- You want to test a specific model version (e.g., `meta-llama/llama-3.1-405b`).

---

## Steps

1. Main window → **Settings** → **Providers**.
2. Find the provider section (OpenRouter or Groq).
3. In the **Model** dropdown, scroll to the bottom and select **Custom…** (or the equivalent custom model entry).
4. A text field appears. Enter the exact model ID as required by the provider's API.
5. Press **Return** or click elsewhere to confirm.

The custom model ID is saved to:
- `Defaults[.openRouterCustomModels]` (array of strings) for OpenRouter
- `Defaults[.groqCustomModels]` (array of strings) for Groq

---

## Finding valid model IDs

### OpenRouter
Browse models at [openrouter.ai/models](https://openrouter.ai/models). The model ID is in the format `provider/model-name`, e.g., `anthropic/claude-3-5-sonnet-20241022`.

### Groq
Browse available models at [console.groq.com/docs/models](https://console.groq.com/docs/models). Groq model IDs are simple strings like `llama-3.3-70b-versatile`.

---

## Test after entering a custom model

After entering a custom model ID, click **Test** to verify the connection works with that specific model. A failed test usually means:
- The model ID has a typo.
- The model is not available on your account tier.
- The model has been deprecated.

---

## Related

- [Supported Models Reference](../reference/supported-models.md) — curated model list
- [Configure Providers](configure-providers.md)
- [App Settings Reference](../reference/app-settings.md) — custom model keys
