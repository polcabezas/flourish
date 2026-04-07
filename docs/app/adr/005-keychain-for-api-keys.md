# ADR-005: Keychain for API Key Storage

**Status:** Superseded by [ADR-015](015-cloudflare-worker-proxy.md)  
**Date:** 2026-04

---

## Decision

Store all LLM provider API keys in the macOS Keychain, not in UserDefaults, files, or any other plaintext storage.

---

## Context

OpenRouter and Groq API keys grant access to paid (or rate-limited) API services. Leaking these keys could result in:
- Unauthorized use and financial charges to the user's account.
- Quota exhaustion.

UserDefaults stores data in a plist file at `~/Library/Preferences/com.personal.flourish.plist`. This file is:
- Readable by any process running as the same user.
- Backed up to iCloud by default (unless excluded).
- Potentially exposed in bug reports or diagnostics tools.

The macOS Keychain encrypts data using the user's login password and hardware security. Access requires the user's authentication and is restricted to the app that created the item (or apps with the same team ID, which in ad-hoc signing is effectively the same app on the same machine).

---

## Alternatives Considered

### UserDefaults (raw or via Defaults package)
Plaintext plist — unacceptable for secrets. Rejected.

### Hardcoded secrets
Not applicable — these are user-provided keys. Mentioned only for completeness.

### Encrypted file in app support directory
Would require managing an encryption key, which itself needs secure storage — a recursive problem. Keychain solves this at the OS level. Rejected.

### Environment variables
Not appropriate for a GUI app. Would require the user to set them before every launch. Rejected.

---

## Decision Rationale

Keychain is the macOS standard for storing sensitive credentials. Every password manager, browser, and cloud sync tool on macOS uses it. The Security framework API is well-documented and battle-tested.

`KeychainService` provides a simple CRUD interface:
- Service: `"com.personal.flourish"` (identifies the set of items belonging to flourish)
- Account: `provider.rawValue` (`"openrouter"` or `"groq"`)

Because flourish uses ad-hoc signing (no team ID), the Keychain items are accessible only to flourish on the machine where they were created. This is acceptable for a personal-use app.

---

## Consequences

- API keys are never written to disk in plaintext. ✓
- Keys survive app updates (Keychain items are not tied to the app binary). ✓
- Keys do not appear in UserDefaults dumps, diagnostics, or bug reports. ✓
- macOS may prompt the user for their login password when flourish first accesses the Keychain (on some OS configurations). This is a one-time event.
- Ad-hoc signing means the Keychain cannot use data protection classes (no `.whenUnlocked` access control that requires Face ID / Touch ID). Items use the default access control, which requires the machine to be unlocked.
- No iCloud Keychain sync (flourish items stay device-local). Acceptable for v1.0.0.

---

## Related

- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [Platform Security Reference](../../platform/security.md)
- [Configure Providers How-To](../how-to/configure-providers.md)
