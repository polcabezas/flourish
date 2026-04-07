# flourish Documentation

flourish is a macOS menu bar application that improves prompts using Large Language Models. It sits silently in your menu bar and surfaces a non-activating overlay panel on a global hotkey, letting you refine any text before sending it to an LLM — then automatically pastes the result back into whatever app you were using.

## Components

| Component | Description |
|-----------|-------------|
| [App](app/index.md) | The macOS application — UI, core services, build system |
| [Platform](platform/security.md) | Cross-cutting security and governance standards |

## Quick Links

| Goal | Link |
|------|------|
| First time using flourish | [Getting Started Tutorial](app/tutorials/getting-started.md) |
| Add an LLM provider | [Add Your First Provider](app/tutorials/add-your-first-provider.md) |
| Create a custom profile | [Create a Custom Profile](app/tutorials/create-custom-profile.md) |
| Architecture overview | [Architecture Reference](app/reference/architecture-overview.md) |
| All settings keys | [App Settings Reference](app/reference/app-settings.md) |
| Keyboard shortcuts | [Keyboard Shortcuts Reference](app/reference/keyboard-shortcuts.md) |
| All ADRs | [ADR Index](app/adr/README.md) |
| Curated reading path | [Books: flourish App](books/flourish-app.md) |

## Changelog

- [v1.2.2](changelog/v1.2.2.md) — Worker bug fix: Pro plan limit now correctly unlimited; reset date hidden for Pro users
- [v1.0-beta](changelog/v1.0-beta.md) — First distributable DMG release (2026-04-07)
- [v1.2.1](changelog/v1.2.1.md) — Pro plan pricing reduced (2,99 €/mo monthly, 29,99 €/yr annual)
- [v1.2.0](changelog/v1.2.0.md) — Lowercase project rename; explicit XcodeGen scheme
- [v1.1.0](changelog/v1.1.0.md) — Target platform picker; forest-green primary buttons
- [v1.0.0](changelog/v1.0.0.md) — Initial release: overlay workflow, dual-provider support, history, profiles, statistics
