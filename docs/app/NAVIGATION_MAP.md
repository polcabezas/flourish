# Navigation Map — Flourish App

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

### Designer (working on UI)
1. [Design System](reference/design-system.md)
2. [Architecture Overview](reference/architecture-overview.md) → UI layer section

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
  └── → reference/database-schema

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
```
