# Book: Flourish App

A curated reading path through the Flourish documentation. Follow this sequence for a complete mental model of the application.

---

## Path 1: User onboarding

For someone using Flourish for the first time.

1. [Getting Started](../app/tutorials/getting-started.md) — Build and run the app
2. [Add Your First Provider](../app/tutorials/add-your-first-provider.md) — Connect an LLM
3. [Keyboard Shortcuts Reference](../app/reference/keyboard-shortcuts.md) — Learn the overlay bindings
4. [Create a Custom Profile](../app/tutorials/create-custom-profile.md) — Tailor the AI's behavior

---

## Path 2: Developer deep-dive

For a developer understanding the codebase end-to-end.

1. [Architecture Overview](../app/reference/architecture-overview.md) — Component map and data flow
2. [File Structure Reference](../app/reference/file-structure.md) — Every source file
3. [Overlay Focus Model](../app/explanation/overlay-focus-model.md) — The core non-activating panel design
4. [Prompt Improvement Workflow](../app/explanation/prompt-improvement-workflow.md) — Full hotkey-to-paste sequence
5. [Paste Automation](../app/explanation/paste-automation.md) — Clipboard + CGEvent mechanics
6. [LLM Provider Abstraction](../app/explanation/llm-provider-abstraction.md) — Protocol design
7. [Data Persistence Strategy](../app/explanation/data-persistence-strategy.md) — Keychain, SQLite, UserDefaults decisions
8. [ADR Index](../app/adr/README.md) — All 14 architectural decisions

---

## Path 3: Security review

For understanding Flourish's security posture.

1. [Platform Security Reference](../platform/security.md) — Full threat model and data flows
2. [ADR-005: Keychain for API Keys](../app/adr/005-keychain-for-api-keys.md)
3. [ADR-008: Ad-hoc Signing](../app/adr/008-adhoc-signing.md)
4. [Paste Automation](../app/explanation/paste-automation.md) — Clipboard handling

---

## Path 4: Extending the app

For adding a new LLM provider or feature.

1. [LLM Service API Reference](../app/reference/llm-service-api.md)
2. [LLM Provider Abstraction](../app/explanation/llm-provider-abstraction.md)
3. [How-To: Add a New LLM Provider](../app/how-to/add-new-llm-provider.md)
4. [Data Models Reference](../app/reference/data-models.md)
5. [App Settings Reference](../app/reference/app-settings.md)
6. [Build Configuration Reference](../app/reference/build-configuration.md)
