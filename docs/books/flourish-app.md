# Book: flourish App

A curated reading path through the flourish documentation. Follow this sequence for a complete mental model of the application.

---

## Path 1: Developer onboarding

For a developer building and running the app for the first time.

1. [Getting Started](../app/tutorials/getting-started.md) — Build and run the app, set up Secrets.xcconfig
2. [How flourish Connects to an LLM](../app/tutorials/add-your-first-provider.md) — Understand the proxy architecture
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
6. [LLM Provider Abstraction](../app/explanation/llm-provider-abstraction.md) — Protocol design and proxy integration
7. [Data Persistence Strategy](../app/explanation/data-persistence-strategy.md) — Info.plist, SQLite, UserDefaults decisions
8. [ADR Index](../app/adr/README.md) — All 31 architectural decisions

---

## Path 3: Security review

For understanding flourish's security posture.

1. [Platform Security Reference](../platform/security.md) — Full threat model and data flows
2. [ADR-015: Cloudflare Worker Proxy](../app/adr/015-cloudflare-worker-proxy.md) — Why and how keys never reach the app
3. [ADR-008: Ad-hoc Signing](../app/adr/008-adhoc-signing.md)
4. [Paste Automation](../app/explanation/paste-automation.md) — Clipboard handling

---

## Path 4: Managing the LLM backend (founders)

For changing the active provider, model, or rotating credentials.

1. [ADR-015: Cloudflare Worker Proxy](../app/adr/015-cloudflare-worker-proxy.md) — Architectural rationale
2. [How-To: Deploy or Update the Worker](../app/how-to/deploy-worker.md) — Full operations guide
3. [How-To: Configure the LLM Provider and Model](../app/how-to/configure-providers.md)
4. [Supported Models Reference](../app/reference/supported-models.md) — Model IDs for wrangler.toml
5. [Build Configuration Reference](../app/reference/build-configuration.md) — Secrets.xcconfig setup

---

## Path 5: Extending the app

For adding a new LLM provider or feature.

1. [LLM Service API Reference](../app/reference/llm-service-api.md)
2. [LLM Provider Abstraction](../app/explanation/llm-provider-abstraction.md)
3. [How-To: Add Support for a New LLM Provider](../app/how-to/add-new-llm-provider.md)
4. [Data Models Reference](../app/reference/data-models.md)
5. [App Settings Reference](../app/reference/app-settings.md)
6. [Build Configuration Reference](../app/reference/build-configuration.md)

---

## Path 6: Managing billing and subscriptions (founders)

For managing user accounts, usage quotas, and subscription plans.

1. [ADR-023: Supabase Auth Strategy](../app/adr/023-supabase-auth-strategy.md) — Auth provider choice and rationale
2. [ADR-024: Auth-Gated UI](../app/adr/024-auth-gated-ui.md) — How sign-in state controls the interface
3. [ADR-025: Cloudflare D1 Usage Tracking](../app/adr/025-cloudflare-d1-usage-tracking.md) — Original metering design (superseded)
4. [ADR-026: Stripe Billing via Worker](../app/adr/026-stripe-billing-via-worker.md) — Subscription and payment flow
5. [ADR-027: Supabase PostgreSQL over D1](../app/adr/027-supabase-postgres-over-d1.md) — Current usage storage layer; replaces D1
6. [ADR-028: ES256 JWT Verification](../app/adr/028-es256-jwt-verification.md) — JWKS-based token verification with caching
7. [ADR-029: Supabase User Lifecycle Triggers](../app/adr/029-supabase-user-lifecycle-triggers.md) — DB triggers for row creation/deletion
8. [ADR-030: Plans and Billing UI](../app/adr/030-plans-billing-ui.md) — Comparison grid, API mapping, retry-on-401
9. [ADR-031: Event-Driven Usage Refresh](../app/adr/031-account-usage-realtime-refresh.md) — NotificationCenter-driven counter updates
10. [How-To: Manage Your Account](../app/how-to/manage-account.md) — User-facing billing flows
11. [How-To: Deploy or Update the Worker](../app/how-to/deploy-worker.md) — Rotate secrets, update Stripe price IDs
