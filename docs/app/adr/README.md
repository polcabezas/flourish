# Architectural Decision Records

A chronological, immutable log of architectural decisions made during the development of flourish.

ADRs are **never modified after acceptance**. If a decision is reversed or superseded, a new ADR is added that references the original.

---

## Index

| # | Title | Status |
|---|-------|--------|
| [001](001-non-activating-panel.md) | Non-activating NSPanel for the overlay | Accepted |
| [002](002-xcodegen.md) | XcodeGen over committed .xcodeproj | Accepted |
| [003](003-grdb-over-coredata.md) | GRDB.swift over CoreData for history storage | Accepted |
| [004](004-defaults-package.md) | Defaults package over raw UserDefaults | Accepted |
| [005](005-keychain-for-api-keys.md) | Keychain for API key storage | Superseded by ADR-015 |
| [006](006-llm-service-protocol.md) | Protocol-based LLM service abstraction | Accepted |
| [007](007-singleton-window-controllers.md) | Singleton pattern for window controllers | Accepted |
| [008](008-adhoc-signing.md) | Ad-hoc code signing | Accepted |
| [009](009-lsuielement.md) | LSUIElement=YES (menu bar agent default) | Accepted |
| [010](010-session-stats-separate.md) | Session stats separate from persisted stats | Accepted |
| [011](011-paste-capture-timing.md) | Capture previous app before showing overlay | Accepted |
| [012](012-history-max-entries.md) | Maximum 500 history entries | Accepted |
| [013](013-base-prompt-placeholder.md) | `{guidelines}` placeholder in base prompt template | Accepted |
| [014](014-draft-save-on-dismiss.md) | Save draft on dismiss, not on every keystroke | Accepted |
| [015](015-cloudflare-worker-proxy.md) | Cloudflare Worker proxy for LLM API access | Accepted |
| [016](016-target-platform-formatting.md) | Per-platform formatting instructions appended to the base prompt | Accepted |
| [017](017-nshosting-controller-for-overlay.md) | NSHostingController over NSHostingView for the overlay panel | Accepted |
| [018](018-outcome-oriented-profiles.md) | Outcome-oriented built-in profiles for non-technical users | Accepted |
| [019](019-ai-generated-profiles.md) | AI-generated guideline profiles via `ProfileGeneratorService` | Accepted |
| [020](020-slim-base-prompt-invariants-only.md) | Slim base prompt — universal invariants only | Accepted |
| [021](021-remove-base-prompt-editor.md) | Remove base prompt editor from Settings UI | Accepted |
| [022](022-lowercase-project-name.md) | Lowercase project name for all technical identifiers | Accepted |
| [023](023-supabase-auth-strategy.md) | Supabase Auth as the authentication provider | Accepted |
| [024](024-auth-gated-ui.md) | Auth-gated UI — sign-in panel shown on launch and sign-out | Accepted |
| [025](025-cloudflare-d1-usage-tracking.md) | Cloudflare D1 for usage tracking | Superseded by ADR-027 |
| [026](026-stripe-billing-via-worker.md) | Stripe billing logic in the Cloudflare Worker | Accepted |
| [027](027-supabase-postgres-over-d1.md) | Supabase PostgreSQL over Cloudflare D1 for usage storage | Accepted |
| [028](028-es256-jwt-verification.md) | ES256 JWT verification with JWKS caching | Accepted |
| [029](029-supabase-user-lifecycle-triggers.md) | Supabase database triggers for user lifecycle | Accepted |
| [030](030-plans-billing-ui.md) | Plans and Billing UI — comparison grid in AccountView | Accepted |
| [031](031-account-usage-realtime-refresh.md) | Event-driven usage refresh in AccountViewModel | Accepted |
| [032](032-git-sync-before-dmg-build.md) | Git sync to `main` before DMG build | Accepted |
| [033](033-limit-reached-popup-window.md) | Separate floating popup for monthly limit reached UI | Accepted |
| [034](034-unlimited-pro-plan.md) | Unlimited improvements for the Pro plan | Accepted |
| [035](035-contentshape-for-plain-button-hit-area.md) | `.contentShape` for plain-button hit areas | Accepted |
| [036](036-rotating-overlay-placeholders.md) | Rotating playful placeholders in the overlay input | Accepted |
| [037](037-loader-success-state-and-paste-detection.md) | Loader success state, AX-based paste detection, and fixed-frame NSHostingView | Accepted |
| [038](038-build-script-version-source-of-truth.md) | `build-dmg.sh` as the single source of truth for the app version | Accepted |

---

## Format

Each ADR contains:
- **Decision** — what was decided
- **Context** — why a decision was needed
- **Alternatives considered** — what else was evaluated
- **Consequences** — what changes as a result
