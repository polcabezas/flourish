/**
 * Flourish Proxy Worker
 *
 * Sits between the Flourish macOS app and LLM providers.
 * The app never holds a real API key — only a proxy bearer token.
 *
 * Required environment variables (set in Cloudflare dashboard or wrangler.toml secrets):
 *   PROXY_TOKEN        — random secret the app sends as Authorization: Bearer <token>
 *   ACTIVE_PROVIDER    — "openrouter" | "groq"
 *   ACTIVE_MODEL       — e.g. "google/gemini-2.0-flash-001"
 *   OPENROUTER_API_KEY — real OpenRouter key (only used when ACTIVE_PROVIDER=openrouter)
 *   GROQ_API_KEY       — real Groq key       (only used when ACTIVE_PROVIDER=groq)
 *
 * To switch provider/model: update env vars in Cloudflare dashboard — no app rebuild needed.
 */

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    // Validate proxy token
    const auth = request.headers.get("Authorization") ?? "";
    if (auth !== `Bearer ${env.PROXY_TOKEN}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    // Parse payload from app: { messages: [{role, content}, ...] }
    let body;
    try {
      body = await request.json();
    } catch {
      return new Response("Bad Request: invalid JSON", { status: 400 });
    }

    if (!Array.isArray(body.messages) || body.messages.length === 0) {
      return new Response("Bad Request: messages array required", { status: 400 });
    }

    const provider = env.ACTIVE_PROVIDER ?? "openrouter";
    const model = env.ACTIVE_MODEL ?? "google/gemini-2.0-flash-001";

    // Build upstream request
    let upstreamURL;
    let apiKey;
    const extraHeaders = {};

    if (provider === "groq") {
      upstreamURL = "https://api.groq.com/openai/v1/chat/completions";
      apiKey = env.GROQ_API_KEY;
    } else {
      upstreamURL = "https://openrouter.ai/api/v1/chat/completions";
      apiKey = env.OPENROUTER_API_KEY;
      extraHeaders["HTTP-Referer"] = "com.personal.flourish";
      extraHeaders["X-Title"] = "Flourish";
    }

    const upstreamBody = {
      model,
      stream: false,
      messages: body.messages,
    };

    let upstreamResponse;
    try {
      upstreamResponse = await fetch(upstreamURL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          ...extraHeaders,
        },
        body: JSON.stringify(upstreamBody),
      });
    } catch (err) {
      return new Response(`Upstream request failed: ${err.message}`, { status: 502 });
    }

    const responseBody = await upstreamResponse.text();

    return new Response(responseBody, {
      status: upstreamResponse.status,
      headers: {
        "Content-Type": "application/json",
        "X-Flourish-Provider": provider,
      },
    });
  },
};
