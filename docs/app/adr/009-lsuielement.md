# ADR-009: LSUIElement=YES (Menu Bar Agent Default)

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Set `LSUIElement = YES` in `Info.plist`, making flourish launch as a menu bar agent by default (no Dock icon, no application menu). Provide a toggle in Settings to show a Dock icon.

---

## Context

A "menu bar agent" (also called a "background app" or "faceless app") is a macOS app that does not appear in the Dock or the application menu bar. It is accessed exclusively via a status item in the system menu bar.

flourish's primary interaction surface is the overlay panel, activated by a global hotkey. The main window (for settings, profiles, history) is a secondary interface. The application does not need a persistent Dock presence.

`LSUIElement = YES` in `Info.plist` sets the app's activation policy to `.accessory` at launch, achieving the menu-bar-agent behavior.

---

## Alternatives Considered

### Standard app (LSUIElement = NO)
Shows a Dock icon and a full application menu. Most macOS users expect tools like flourish to live in the menu bar only. A Dock icon would be unexpected and add visual clutter. Rejected as default, but offered as a user preference.

### Launch as agent, no toggle
Maximum minimalism. However, some users prefer a Dock icon for easier Command+Tab access to the main window. The toggle accommodates both preferences.

---

## Decision Rationale

Menu bar agents are the established macOS pattern for system utilities, clipboard managers, and AI tools (Raycast, Wispr Flow, 1Password mini). Users in this space expect no Dock icon by default.

The Show Dock Icon toggle (`Defaults[.showDockIcon]`) calls:
```swift
NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
```

This changes the policy at runtime. When `.regular` is set, the app gains a Dock icon and a standard application menu. When `.accessory` is set, both disappear.

---

## Consequences

- App launches with no Dock icon. ✓
- Menu bar icon (wand) is the only persistent visual. ✓
- Global hotkey provides the primary access path — no need to find the app in the Dock. ✓
- Users who want a Dock icon can enable it in Settings → General. ✓
- The app does not appear in Cmd+Tab by default (`.accessory` policy). With the Dock icon enabled (`.regular` policy), it appears in Cmd+Tab. ✓
- Some macOS accessibility features and system UI interactions behave differently for `.accessory` vs `.regular` apps. No issues observed for flourish's use cases.

---

## Related

- [App Settings Reference](../reference/app-settings.md) — `showDockIcon` key
- [Build Configuration Reference](../reference/build-configuration.md) — `LSUIElement` in Info.plist
