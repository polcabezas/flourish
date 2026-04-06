# ADR-008: Ad-Hoc Code Signing

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Sign Flourish with ad-hoc signing (identity: `-`) rather than a Developer ID certificate. Do not enable Hardened Runtime or notarization.

---

## Context

Flourish is a personal-use tool, not a commercial product distributed through the Mac App Store or official channels. Code signing in macOS exists on a spectrum:

1. **No signing** — macOS Gatekeeper blocks the app entirely on most systems.
2. **Ad-hoc signing** — App is signed with a self-generated identity. Runs on the build machine without Gatekeeper issues. Shows a warning on other machines (right-click → Open to bypass).
3. **Developer ID signed** — Requires an Apple Developer Program membership ($99/year). Allows distribution to arbitrary users without Gatekeeper warnings.
4. **Notarized** — Developer ID + Apple's scan + stapled ticket. Provides the strongest trust for distributed apps.
5. **App Store** — Sandboxed, App Store reviewed.

Flourish requires **no App Sandbox** (CGEvent paste simulation is blocked by the sandbox). This eliminates option 5 and makes option 4 more complex (notarization requires Hardened Runtime, which has its own capability implications).

---

## Alternatives Considered

### Developer ID signing (no notarization)
Would allow distribution to other machines without Gatekeeper warnings. Requires $99/year Apple Developer membership. Unnecessary for personal use. Can be added later if distribution scope changes.

### Notarization
Requires Developer ID + Hardened Runtime. Hardened Runtime restricts CGEvent posting and may require entitlements. Additional complexity for no current benefit. Can be added later.

### App Sandbox
Fundamentally incompatible with CGEvent paste simulation (sandboxed apps cannot post events to other apps without specific entitlements that Apple does not grant for this purpose).

---

## Decision Rationale

Ad-hoc signing satisfies the current requirements:
- The app runs without issues on the developer's machine.
- Other users who receive the `.app` or `.dmg` can open it with right-click → Open.
- No certificate management or Apple Developer account is required.
- No Hardened Runtime entitlements needed.

If Flourish is ever distributed publicly, upgrading to Developer ID + notarization is a configuration change in `project.yml` — no code changes required.

---

## Consequences

- App runs without issues on the build machine. ✓
- On other machines, first launch requires right-click → Open to bypass Gatekeeper. (User experience trade-off.)
- No notarization ticket → Gatekeeper always checks with Apple's servers on first open (if online). Acceptable.
- Keychain items cannot use data protection access control classes (no biometric unlock). Default Keychain access used instead. ✓
- `Flourish.entitlements` has no sandbox entitlement. `com.apple.security.app-sandbox = false`. ✓

---

## Related

- [Build Configuration Reference](../reference/build-configuration.md)
- [How-To: Build and Distribute](../how-to/build-and-distribute.md)
- [ADR-005: Keychain for API Keys](005-keychain-for-api-keys.md)
