# Security Reference

Cross-cutting security standards and threat model for the Flourish macOS application.

---

## Threat Model

Flourish operates in a threat model where the primary concern is:
1. **API key exposure** — keys grant access to paid LLM services.
2. **Clipboard interception** — the app reads and writes the system clipboard.
3. **Synthetic input injection** — the app posts synthetic keystrokes via CGEvent.

Flourish does not:
- Store any of the user's actual prompts in the cloud.
- Transmit any data other than the text the user explicitly types in the overlay (sent to the selected LLM provider's API).
- Have network access beyond the two provider API endpoints.
- Run background daemons or install kernel extensions.

---

## API Key Security

**Storage:** macOS Keychain  
**Service:** `com.personal.flourish`  
**Accounts:** `openrouter`, `groq`

API keys are written to the Keychain when the user saves settings, and read from the Keychain at the start of each LLM request. They are never written to disk in plaintext, never included in logs, and never exposed in crash reports.

The Keychain is encrypted with the user's login password. Items are accessible only when the user's session is unlocked.

**Note on ad-hoc signing:** Without a Developer ID, Keychain access control is limited to the standard (not data-protected) class. Biometric authentication (Touch ID / Face ID) cannot be required for Keychain access in this configuration. See [ADR-005](../app/adr/005-keychain-for-api-keys.md) and [ADR-008](../app/adr/008-adhoc-signing.md).

---

## Accessibility Permission

Flourish requests the Accessibility permission (`com.apple.private.accessibility.inspection.install`) to post `CGEvent` synthetic keystrokes.

**Scope:** The permission is used exclusively to simulate Cmd+V after an LLM response is received. No other accessibility APIs are used.

**User grant:** Required via System Settings → Privacy & Security → Accessibility. The user must explicitly add Flourish to the permitted list.

**Proactive request:** At launch, Flourish calls `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` to trigger the system permission dialog. If denied, Flourish shows an instructional alert before each paste attempt.

---

## Clipboard Security

Flourish reads the clipboard contents at overlay open time to save and restore them after pasting. The saved clipboard data is:
- Held in memory in `PasteService` for the duration of the LLM call (typically <10 seconds).
- Discarded after restoration.
- Never written to disk.
- Never sent to any network endpoint.

**Limitation:** If the clipboard contains sensitive data (passwords, private keys) at the moment the user presses the Flourish hotkey, that data is briefly stored in memory and then restored to the clipboard. This is inherent to the paste automation approach. Users should not invoke Flourish immediately after copying a password.

---

## Network Security

All LLM API calls use HTTPS with TLS. `URLSession` enforces certificate validation by default (App Transport Security).

Flourish sends to exactly two endpoints:
- `https://openrouter.ai/api/v1/chat/completions`
- `https://api.groq.com/openai/v1/chat/completions`

No other network calls are made. No analytics, no telemetry, no update checks.

The only data sent to these endpoints:
- The assembled system prompt (base template + profile guidelines).
- The user's typed prompt text.
- The `HTTP-Referer: com.personal.flourish` and `X-Title: Flourish` headers (OpenRouter only — identifies the app to OpenRouter's usage dashboard, not to any Flourish server).

---

## App Sandbox

Flourish does not use the macOS App Sandbox (`com.apple.security.app-sandbox = false`). The sandbox is incompatible with:
- Posting `CGEvent` synthetic keystrokes to other applications.
- Reactivating other applications via `NSRunningApplication.activate()`.

This is a known and accepted trade-off. See [ADR-008](../app/adr/008-adhoc-signing.md).

**Implication:** Flourish runs with full user-level permissions. It can read and write any file the user can access, make unrestricted network calls, and interact with any application. This is standard for productivity utilities that require system-level integration.

---

## Data at Rest

| Data | Location | Encryption |
|------|----------|-----------|
| API keys | macOS Keychain | OS-level encryption |
| Prompt history | `~/.local/share/com.personal.flourish/history.db` | None (plaintext SQLite) |
| Settings, profiles | `~/Library/Preferences/com.personal.flourish.plist` | None (plaintext plist) |
| Overlay draft | `~/Library/Preferences/com.personal.flourish.plist` | None |

The prompt history and settings are stored in plaintext. Users who require encryption for their prompt history should use FileVault (macOS full-disk encryption), which encrypts the entire `~/Library` and `~/.local` paths.

---

## Data Transmission Summary

| What | Where | When |
|------|-------|------|
| System prompt + user's typed text | Active LLM provider (OpenRouter or Groq) | On each overlay submit |
| Nothing else | — | Never |

No data is sent to any Flourish server (there is none). The app is entirely client-side.

---

## Related

- [ADR-005: Keychain for API Keys](../app/adr/005-keychain-for-api-keys.md)
- [ADR-008: Ad-hoc Signing](../app/adr/008-adhoc-signing.md)
- [Paste Automation Explanation](../app/explanation/paste-automation.md)
- [Overlay Focus Model Explanation](../app/explanation/overlay-focus-model.md)
