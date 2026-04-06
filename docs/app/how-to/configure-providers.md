# Configure Providers

How to manage OpenRouter and Groq provider settings: API keys, model selection, enabling/disabling, and testing connectivity.

---

## Add or update an API key

1. Main window → **Settings** → **Providers** section.
2. Find the provider (OpenRouter or Groq).
3. Toggle the provider on if it's off.
4. Click the API key field (it's a secure field — text is hidden).
5. Paste or type the new key.
6. Click **Test** to verify.

API keys are stored in macOS Keychain under:
- Service: `com.personal.flourish`
- Account: `openrouter` or `groq`

They are never written to UserDefaults or any file on disk.

---

## Test provider connectivity

Click **Test** next to a provider's key field. Flourish makes a real (minimal) API call using your key and selected model. The result shows:
- Green ✓ — connection succeeded, model responded
- Red ✗ — connection failed (bad key, no balance, rate limit, etc.)

If the test fails, check:
- The API key is correct and not expired.
- The provider account has sufficient credit (OpenRouter only).
- The selected model is available to your account tier.

---

## Change the active provider

The **Active Provider** segmented control at the top of the Providers section sets the default for all new overlay sessions. It writes to `Defaults[.activeProvider]`.

You can also switch per-request in the overlay toolbar's provider picker — this change persists until you close the overlay.

---

## Enable or disable a provider

Each provider has an on/off toggle. Disabling a provider:
- Prevents it from appearing in the overlay's provider picker.
- Retains the stored API key in Keychain.
- Retains the saved model selection.

---

## Change the selected model

In the Settings → Providers section, each provider has a **Model** dropdown. Select from the curated list or enter a custom model ID (see [Use Custom Models](use-custom-models.md)).

The selected model is stored in:
- `Defaults[.openRouterModel]` for OpenRouter
- `Defaults[.groqModel]` for Groq

See [Supported Models](../reference/supported-models.md) for the full curated list with pricing.

---

## Remove an API key

Currently there is no "Delete key" button in the UI. To remove a key:

1. In Settings, clear the key field and leave it empty.
2. The key in Keychain is replaced with an empty string on the next save event.

Alternatively, open **Keychain Access** (macOS app), search for `com.personal.flourish`, and delete the relevant entry.

---

## Related

- [Supported Models Reference](../reference/supported-models.md)
- [Use Custom Models](use-custom-models.md)
- [App Settings Reference](../reference/app-settings.md)
- [ADR-005: Keychain for API keys](../adr/005-keychain-for-api-keys.md)
