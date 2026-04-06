# App Documentation

Documentation for the Flourish macOS application — a menu bar prompt-improvement tool built with Swift, SwiftUI, and AppKit.

## Navigation

| Section | What you'll find |
|---------|-----------------|
| [Tutorials](tutorials/getting-started.md) | Step-by-step guided learning for new developers and users |
| [How-To Guides](how-to/configure-providers.md) | Task-oriented recipes for specific goals |
| [Reference](reference/architecture-overview.md) | Exact specifications: APIs, schemas, settings, file structure |
| [Explanation](explanation/overlay-focus-model.md) | Architecture rationale and design concepts |
| [ADRs](adr/README.md) | Architectural Decision Records (immutable audit trail) |

## Tutorials

- [Getting Started](tutorials/getting-started.md) — Build, run, and use Flourish for the first time
- [Add Your First Provider](tutorials/add-your-first-provider.md) — Connect OpenRouter or Groq and make your first improvement
- [Create a Custom Profile](tutorials/create-custom-profile.md) — Write a custom guideline profile for a specific use case

## How-To Guides

- [Configure Providers](how-to/configure-providers.md) — Manage OpenRouter and Groq API keys and models
- [Manage Profiles](how-to/manage-profiles.md) — Create, edit, and delete guideline profiles
- [Customize the Keyboard Shortcut](how-to/customize-shortcut.md) — Change the global hotkey
- [Navigate History in the Overlay](how-to/navigate-history.md) — Browse past prompts without leaving the overlay
- [Use Custom Models](how-to/use-custom-models.md) — Enter an arbitrary model ID not in the default list
- [Build and Distribute](how-to/build-and-distribute.md) — Generate an Xcode project and package a DMG
- [Add a New LLM Provider](how-to/add-new-llm-provider.md) — Extend the app with a third provider

## Reference

- [Architecture Overview](reference/architecture-overview.md) — Full component map and data flow
- [Design System](reference/design-system.md) — Colors, typography, spacing, and layout constants
- [App Settings](reference/app-settings.md) — All `Defaults.Key` definitions and their types
- [Data Models](reference/data-models.md) — Swift model types: GuidelineProfile, HistoryEntry, LLMProvider, ModelOption
- [LLM Service API](reference/llm-service-api.md) — Protocol, request/response shape, error types
- [Keyboard Shortcuts](reference/keyboard-shortcuts.md) — All keyboard bindings in overlay and main window
- [Database Schema](reference/database-schema.md) — SQLite schema, migrations, and query patterns
- [File Structure](reference/file-structure.md) — Every source file and its purpose
- [Build Configuration](reference/build-configuration.md) — XcodeGen, Makefile, entitlements, signing
- [Supported Models](reference/supported-models.md) — All built-in models with pricing

## Explanation

- [Overlay Focus Model](explanation/overlay-focus-model.md) — Why the overlay uses a non-activating NSPanel
- [LLM Provider Abstraction](explanation/llm-provider-abstraction.md) — Protocol-based design and how to extend it
- [Data Persistence Strategy](explanation/data-persistence-strategy.md) — When to use Keychain, SQLite, UserDefaults, or session state
- [Prompt Improvement Workflow](explanation/prompt-improvement-workflow.md) — Full flow from hotkey to pasted result
- [Paste Automation](explanation/paste-automation.md) — How clipboard capture, CGEvent, and app reactivation work together

## ADRs

See [ADR Index](adr/README.md) for the full list of 14 architectural decisions.
