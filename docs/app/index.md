# App Documentation

Documentation for the flourish macOS application — a menu bar prompt-improvement tool built with Swift, SwiftUI, and AppKit.

flourish v1.2 adds user accounts, authentication (Supabase), per-user usage tracking (Supabase PostgreSQL), and billing (Stripe). All core prompt-improvement functionality is auth-gated. See [ADR-023](adr/023-supabase-auth-strategy.md) through [ADR-037](adr/037-loader-success-state-and-paste-detection.md) for the architectural decisions behind these features.

## Navigation

| Section | What you'll find |
|---------|-----------------|
| [Tutorials](tutorials/getting-started.md) | Step-by-step guided learning for new developers |
| [How-To Guides](how-to/configure-providers.md) | Task-oriented recipes for specific goals |
| [Reference](reference/architecture-overview.md) | Exact specifications: APIs, schemas, settings, file structure |
| [Explanation](explanation/overlay-focus-model.md) | Architecture rationale and design concepts |
| [ADRs](adr/README.md) | Architectural Decision Records (immutable audit trail) |

## Tutorials

- [Getting Started](tutorials/getting-started.md) — Build, run, and use flourish for the first time
- [How flourish Connects to an LLM](tutorials/add-your-first-provider.md) — How the proxy architecture works and how to set up for development
- [Create a Custom Profile](tutorials/create-custom-profile.md) — Write a custom guideline profile for a specific use case

## How-To Guides

- [Manage Your Account](how-to/manage-account.md) — Sign in, view usage, upgrade your plan, and manage billing
- [Configure the LLM Provider and Model](how-to/configure-providers.md) — Change provider or model via the Cloudflare Worker (founders only)
- [Deploy or Update the Worker](how-to/deploy-worker.md) — Full Worker deployment and operations guide
- [Change the Active Model](how-to/use-custom-models.md) — Set ACTIVE_MODEL in wrangler.toml
- [Add Support for a New LLM Provider](how-to/add-new-llm-provider.md) — Extend the Worker and flourishProxyService
- [Manage Profiles](how-to/manage-profiles.md) — Create, edit, and delete guideline profiles
- [Customize the Keyboard Shortcut](how-to/customize-shortcut.md) — Change the global hotkey
- [Navigate History in the Overlay](how-to/navigate-history.md) — Browse past prompts without leaving the overlay
- [Build and Distribute](how-to/build-and-distribute.md) — Generate an Xcode project and package a DMG

## Reference

- [Architecture Overview](reference/architecture-overview.md) — Full component map and data flow
- [Design System](reference/design-system.md) — Colors, typography, spacing, and layout constants
- [App Settings](reference/app-settings.md) — All `Defaults.Key` definitions and their types
- [Data Models](reference/data-models.md) — Swift model types: GuidelineProfile, HistoryEntry, TargetPlatform, ModelOption
- [LLM Service API](reference/llm-service-api.md) — Protocol, flourishProxyService, request/response shape, error types
- [Keyboard Shortcuts](reference/keyboard-shortcuts.md) — All keyboard bindings in overlay and main window
- [Database Schema](reference/database-schema.md) — SQLite schema, migrations, and query patterns
- [File Structure](reference/file-structure.md) — Every source file and its purpose
- [Build Configuration](reference/build-configuration.md) — XcodeGen, Secrets.xcconfig, Makefile, entitlements, signing
- [Supported Models](reference/supported-models.md) — Model IDs and pricing for use in wrangler.toml
- [Worker API Reference](reference/worker-api.md) — All 6 Worker endpoint contracts (request/response, auth, error codes)

## Explanation

- [Overlay Focus Model](explanation/overlay-focus-model.md) — Why the overlay uses a non-activating NSPanel
- [LLM Provider Abstraction](explanation/llm-provider-abstraction.md) — Protocol-based design and how the proxy fits into it
- [Data Persistence Strategy](explanation/data-persistence-strategy.md) — When to use Info.plist, SQLite, UserDefaults, or session state
- [Prompt Improvement Workflow](explanation/prompt-improvement-workflow.md) — Full flow from hotkey to pasted result
- [Paste Automation](explanation/paste-automation.md) — How clipboard capture, CGEvent, and app reactivation work together

## ADRs

See [ADR Index](adr/README.md) for the full list of 38 architectural decisions.
