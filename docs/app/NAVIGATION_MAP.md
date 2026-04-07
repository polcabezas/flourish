# Navigation Map — flourish App

## Entry Points by Persona

### New developer (first run)
1. [Getting Started](tutorials/getting-started.md)
2. [Keyboard Shortcuts Reference](reference/keyboard-shortcuts.md)
3. [Create a Custom Profile](tutorials/create-custom-profile.md)

### Developer (new to this codebase)
1. [Architecture Overview](reference/architecture-overview.md)
2. [File Structure](reference/file-structure.md)
3. [Overlay Focus Model](explanation/overlay-focus-model.md)
4. [Prompt Improvement Workflow](explanation/prompt-improvement-workflow.md)
5. [Build Configuration](reference/build-configuration.md)
6. [ADR Index](adr/README.md)

### Developer (extending the app)
1. [LLM Service API](reference/llm-service-api.md)
2. [LLM Provider Abstraction](explanation/llm-provider-abstraction.md)
3. [Add Support for a New LLM Provider](how-to/add-new-llm-provider.md)
4. [Deploy or Update the Worker](how-to/deploy-worker.md)
5. [Data Models](reference/data-models.md)

### Developer (debugging persistence)
1. [Database Schema](reference/database-schema.md)
2. [App Settings](reference/app-settings.md)
3. [Data Persistence Strategy](explanation/data-persistence-strategy.md)

### Founder (managing the LLM backend)
1. [ADR-015: Cloudflare Worker Proxy](adr/015-cloudflare-worker-proxy.md)
2. [Deploy or Update the Worker](how-to/deploy-worker.md)
3. [Configure the LLM Provider and Model](how-to/configure-providers.md)
4. [Supported Models Reference](reference/supported-models.md)

### Founder (managing billing and subscriptions)
1. [ADR-026: Stripe Billing via Worker](adr/026-stripe-billing-via-worker.md)
2. [How to Manage Your Account](how-to/manage-account.md) — user-facing billing flows
3. [ADR-034: Unlimited improvements for the Pro plan](adr/034-unlimited-pro-plan.md) — Pro has no monthly cap
4. [ADR-033: Separate floating popup for monthly limit reached UI](adr/033-limit-reached-popup-window.md) — Free plan UX on limit hit
5. [ADR-031: Event-Driven Usage Refresh in AccountViewModel](adr/031-account-usage-realtime-refresh.md)
6. [Deploy or Update the Worker](how-to/deploy-worker.md)

### Founder (building and distributing)
1. [Build and Distribute](how-to/build-and-distribute.md)
2. [ADR-032: Git sync to `main` before DMG build](adr/032-git-sync-before-dmg-build.md) — reproducible DMG builds from clean `main`
3. [ADR-008: Ad-hoc code signing](adr/008-adhoc-signing.md)

### Designer (working on UI)
1. [Design System](reference/design-system.md)
2. [Architecture Overview](reference/architecture-overview.md) → UI layer section
3. [ADR-035: `.contentShape` for plain-button hit areas](adr/035-contentshape-for-plain-button-hit-area.md) — required pattern for `.buttonStyle(.plain)` with padding
4. [ADR-036: Rotating overlay placeholders](adr/036-rotating-overlay-placeholders.md) — copy pool, ZStack placement, and opacity rationale
5. [ADR-037: Loader success state and paste detection](adr/037-loader-success-state-and-paste-detection.md) — spinner → checkmark transition, fixed-frame NSHostingView pattern

## Diataxis Cross-Links

```
tutorials/getting-started
  ├── → how-to/deploy-worker         (for proxy setup context)
  └── → reference/keyboard-shortcuts

tutorials/add-your-first-provider    (now explains proxy model for devs)
  ├── → tutorials/getting-started
  └── → adr/015-cloudflare-worker-proxy

tutorials/create-custom-profile
  └── → how-to/manage-profiles

explanation/overlay-focus-model
  ├── → adr/001-non-activating-panel
  └── → explanation/paste-automation

explanation/prompt-improvement-workflow
  ├── → explanation/paste-automation
  ├── → reference/llm-service-api
  ├── → reference/database-schema
  └── → adr/016-target-platform-formatting

explanation/data-persistence-strategy
  ├── → adr/003-grdb-over-coredata
  ├── → adr/004-defaults-package
  ├── → adr/015-cloudflare-worker-proxy
  └── → reference/database-schema

explanation/llm-provider-abstraction
  ├── → adr/006-llm-service-protocol
  ├── → adr/015-cloudflare-worker-proxy
  ├── → reference/llm-service-api
  └── → how-to/add-new-llm-provider

reference/architecture-overview
  ├── → explanation/*
  └── → adr/README

how-to/deploy-worker
  ├── → adr/015-cloudflare-worker-proxy
  ├── → reference/build-configuration
  └── → platform/security

how-to/manage-account
  ├── → adr/023-supabase-auth-strategy
  ├── → adr/024-auth-gated-ui
  ├── → adr/026-stripe-billing-via-worker
  ├── → adr/027-supabase-postgres-over-d1
  ├── → adr/031-account-usage-realtime-refresh
  ├── → adr/033-limit-reached-popup-window
  ├── → adr/034-unlimited-pro-plan
  └── → reference/data-models

reference/design-system (Interactive State Conventions)
  ├── → adr/030-plans-billing-ui        (original .contentShape fix for Upgrade button)
  ├── → adr/035-contentshape-for-plain-button-hit-area  (canonical pattern for .plain buttons)
  └── → adr/036-rotating-overlay-placeholders  (copy pool, ZStack placement, opacity rationale)

how-to/build-and-distribute
  └── → adr/032-git-sync-before-dmg-build  (clean main required before DMG build)

explanation/paste-automation
  ├── → adr/011-paste-capture-timing
  ├── → adr/037-loader-success-state-and-paste-detection  (AX check, clipboard-retain, success pill)
  └── → adr/001-non-activating-panel
```
