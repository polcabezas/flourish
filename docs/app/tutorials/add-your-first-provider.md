# Add Your First Provider

**Goal:** Connect an LLM provider (OpenRouter or Groq), verify the connection, and select a model — so Flourish can improve prompts.

**Time:** ~10 minutes

**Prerequisites:**
- Flourish built and running (see [Getting Started](getting-started.md))
- An account at [OpenRouter](https://openrouter.ai) or [Groq](https://console.groq.com)

---

## About the two providers

| | OpenRouter | Groq |
|---|---|---|
| What it is | Aggregator routing to many model families | LPU inference cloud for open models |
| Free tier | No (pay-per-token) | Yes (generous rate limits) |
| Model variety | Very high (Claude, GPT-4, Gemini, Llama, Mistral, …) | Moderate (Llama, Mixtral, Gemma) |
| Speed | Varies by model | Very fast (LPU hardware) |
| Cost | Per-token (tracked by Flourish) | Free for supported models |

**Recommendation for first-timers:** Start with Groq — it's free and fast.

---

## Option A — Set up Groq

### 1. Get a Groq API key

1. Go to [console.groq.com](https://console.groq.com).
2. Sign up or log in.
3. Navigate to **API Keys** → **Create API Key**.
4. Copy the key.

### 2. Enter the key in Flourish

1. Open Flourish's main window → **Settings**.
2. Under **Providers**, find the **Groq** section.
3. Toggle Groq **on**.
4. Paste your key into the secure field.
5. Click **Test** — you should see a green ✓.

### 3. Select a Groq model

From the model dropdown, choose a model. Recommended starting point:

| Model | Notes |
|-------|-------|
| Llama 3.3 70B Versatile | Best quality, still fast |
| Llama 3.1 8B Instant | Fastest, good for short prompts |

### 4. Set Groq as the active provider

In the **Active Provider** segmented control at the top of the Providers section, select **Groq**.

---

## Option B — Set up OpenRouter

### 1. Get an OpenRouter API key

1. Go to [openrouter.ai](https://openrouter.ai).
2. Sign up or log in.
3. Navigate to **Keys** → **Create Key**.
4. Add credit to your account (minimum $1 is sufficient for extensive testing).
5. Copy the key.

### 2. Enter the key in Flourish

1. Open Flourish's main window → **Settings**.
2. Under **Providers**, find the **OpenRouter** section.
3. Toggle OpenRouter **on**.
4. Paste your key into the secure field.
5. Click **Test** — you should see a green ✓.

### 3. Select an OpenRouter model

Recommended starting models:

| Model | Cost | Notes |
|-------|------|-------|
| Gemini 2.0 Flash | Very low | Fast, high quality |
| GPT-4o Mini | Very low | Reliable, well-rounded |
| Claude 3 Haiku | Low | Excellent at following instructions |

### 4. Set OpenRouter as the active provider

In the **Active Provider** segmented control, select **OpenRouter**.

---

## Step — Test with a real prompt

1. Press **Ctrl+Space** to open the overlay.
2. Type: `i need help writing thing for work`
3. Press **Return**.
4. The improved prompt is pasted back. Check the result.

---

## Switching providers on the fly

In the overlay toolbar, the provider picker lets you switch the active provider per-request without going to Settings. This is useful when you want Groq's speed for quick improvements and OpenRouter's quality for complex prompts.

---

## Next Steps

- [Create a Custom Profile](create-custom-profile.md) — control how the AI rewrites your prompts
- [Supported Models Reference](../reference/supported-models.md) — full model list with pricing
- [Use Custom Models](../how-to/use-custom-models.md) — enter any model ID not in the default list
