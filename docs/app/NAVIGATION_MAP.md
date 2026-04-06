# Navigation Map — Flourish App

## Entry Points by Persona

### New user (first run)
1. [Getting Started](tutorials/getting-started.md)
2. [Add Your First Provider](tutorials/add-your-first-provider.md)
3. [Keyboard Shortcuts Reference](reference/keyboard-shortcuts.md)

### Developer (new to this codebase)
1. [Architecture Overview](reference/architecture-overview.md)
2. [File Structure](reference/file-structure.md)
3. [Overlay Focus Model](explanation/overlay-focus-model.md)
4. [Prompt Improvement Workflow](explanation/prompt-improvement-workflow.md)
5. [Build Configuration](reference/build-configuration.md)
6. [ADR Index](adr/README.md)

### Developer (extending the app)
1. [LLM Service API](reference/llm-service-api.md)
2. [Add a New LLM Provider](how-to/add-new-llm-provider.md)
3. [LLM Provider Abstraction](explanation/llm-provider-abstraction.md)
4. [Data Models](reference/data-models.md)

### Developer (debugging persistence)
1. [Database Schema](reference/database-schema.md)
2. [App Settings](reference/app-settings.md)
3. [Data Persistence Strategy](explanation/data-persistence-strategy.md)

### Designer (working on UI)
1. [Design System](reference/design-system.md)
2. [Architecture Overview](reference/architecture-overview.md) → UI layer section

## Diataxis Cross-Links

```
tutorials/getting-started
  ├── → how-to/configure-providers
  └── → reference/keyboard-shortcuts

tutorials/add-your-first-provider
  ├── → reference/supported-models
  └── → how-to/use-custom-models

tutorials/create-custom-profile
  └── → how-to/manage-profiles

explanation/overlay-focus-model
  ├── → adr/001-non-activating-panel
  └── → explanation/paste-automation

explanation/prompt-improvement-workflow
  ├── → explanation/paste-automation
  ├── → reference/llm-service-api
  └── → reference/database-schema

explanation/data-persistence-strategy
  ├── → adr/003-grdb-over-coredata
  ├── → adr/004-defaults-package
  ├── → adr/005-keychain-for-api-keys
  └── → reference/database-schema

explanation/llm-provider-abstraction
  ├── → adr/006-llm-service-protocol
  ├── → reference/llm-service-api
  └── → how-to/add-new-llm-provider

reference/architecture-overview
  ├── → explanation/*
  └── → adr/README
```
