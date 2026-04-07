# Security Reference

Cross-cutting security standards and threat model for the flourish macOS application.

---

## Threat Model

flourish operates in a threat model where the primary concerns are:
1. **Proxy token exposure** — the bearer token embedded in the app authenticates to the Cloudflare Worker; if extracted, an attacker could use it to make proxied LLM requests at the company's expense.
2. **Clipboard interception** — the app reads and writes the system clipboard.
3. **Synthetic input injection** — the app posts synthetic keystrokes via CGEvent.

flourish does not:
- Store any of the user's actual prompts in the cloud.
- Transmit any data other than the text the user explicitly types in the overlay (sent to the Cloudflare Worker proxy, which forwards it to the configured LLM provider).
- Have network access beyond the single proxy endpoint.
- Run background daemons or install kernel extensions.

---

## API Key Security

LLM provider API keys (OpenRouter, Groq) are **never present in the app binary or on user devices**. They are stored as Cloudflare secrets in the Worker and are not visible in `worker.js`, `wrangler.toml`, the Cloudflare dashboard logs, or any distributed artifact.

See [ADR-015: Cloudflare Worker Proxy](../app/adr/015-cloudflare-worker-proxy.md).

---

## Proxy Bearer Token

**Storage:** `Secrets.xcconfig` (gitignored) → `Info.plist` (build-time injection)  
**Runtime access:** Read from `Bundle.main.infoDictionary` by `flourishProxyService`

The proxy bearer token (`flourish_PROXY_TOKEN`) authenticates flourish app instances to the Cloudflare Worker. It is:
- Never hardcoded in source files.
- Injected into the binary at build time via `Secrets.xcconfig` → build settings → `Info.plist`.
- Not stored in the Keychain (it is a build-time constant, not a user-managed secret).

**Risk:** A determined attacker can extract the token from a distributed binary using `strings` or a disassembler. This is an accepted trade-off at the current stage. Mitigation options include per-device tokens, short-lived JWTs, or certificate pinning — these can be added to the Worker without an app change.

**Rotation:** Update the Cloudflare secret (`wrangler secret put flourish_PROXY_TOKEN`) and issue a new app build.

---

## Accessibility Permission

flourish requests the Accessibility permission to post `CGEvent` synthetic keystrokes.

**Scope:** The permission is used exclusively to simulate Cmd+V after an LLM response is received. No other accessibility APIs are used.

**User grant:** Required via System Settings → Privacy & Security → Accessibility. The user must explicitly add flourish to the permitted list.

**Proactive request:** At launch, flourish calls `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` to trigger the system permission dialog. If denied, flourish shows an instructional alert before each paste attempt.

---

## Clipboard Security

flourish reads the clipboard contents at overlay open time to save and restore them after pasting. The saved clipboard data is:
- Held in memory in `PasteService` for the duration of the LLM call (typically <10 seconds).
- Discarded after restoration.
- Never written to disk.
- Never sent to any network endpoint.

**Limitation:** If the clipboard contains sensitive data (passwords, private keys) at the moment the user presses the flourish hotkey, that data is briefly stored in memory and then restored to the clipboard. This is inherent to the paste automation approach. Users should not invoke flourish immediately after copying a password.

---

## Network Security

All outbound network calls use HTTPS with TLS. `URLSession` enforces certificate validation by default (App Transport Security).

flourish sends to exactly one endpoint:
- `https://<flourish_PROXY_URL>/improve` — the Cloudflare Worker proxy

The Worker then calls the configured LLM provider (OpenRouter or Groq) server-side. The app itself never contacts provider APIs directly.

No other network calls are made. No analytics, no telemetry, no update checks.

The only data sent to the proxy:
- The assembled system prompt (base template + profile guidelines).
- The user's typed prompt text.

---

## App Sandbox

flourish does not use the macOS App Sandbox (`com.apple.security.app-sandbox = false`). The sandbox is incompatible with:
- Posting `CGEvent` synthetic keystrokes to other applications.
- Reactivating other applications via `NSRunningApplication.activate()`.

This is a known and accepted trade-off. See [ADR-008](../app/adr/008-adhoc-signing.md).

**Implication:** flourish runs with full user-level permissions. It can read and write any file the user can access, make unrestricted network calls, and interact with any application. This is standard for productivity utilities that require system-level integration.

---

## Data at Rest

| Data | Location | Encryption |
|------|----------|-----------|
| Proxy token | `Info.plist` inside the app bundle | None (embedded at build time; protected by app distribution controls) |
| Prompt history | `~/.local/share/com.personal.flourish/history.db` | None (plaintext SQLite) |
| Settings, profiles | `~/Library/Preferences/com.personal.flourish.plist` | None (plaintext plist) |
| Overlay draft | `~/Library/Preferences/com.personal.flourish.plist` | None |

The prompt history and settings are stored in plaintext. Users who require encryption for their prompt history should use FileVault (macOS full-disk encryption), which encrypts the entire `~/Library` and `~/.local` paths.

---

## Data Transmission Summary

| What | Where | When |
|------|-------|------|
| System prompt + user's typed text | Cloudflare Worker proxy (`/improve`) | On each overlay submit |
| Worker forwards to | Configured LLM provider (OpenRouter or Groq) | On each overlay submit |
| Nothing else | — | Never |

No data is sent to any flourish-operated server beyond the Cloudflare Worker. The Worker is the sole intermediary.

---

## Related

- [ADR-015: Cloudflare Worker Proxy](../app/adr/015-cloudflare-worker-proxy.md)
- [ADR-008: Ad-hoc Signing](../app/adr/008-adhoc-signing.md)
- [Paste Automation Explanation](../app/explanation/paste-automation.md)
- [Overlay Focus Model Explanation](../app/explanation/overlay-focus-model.md)
