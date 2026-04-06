# Architectural Decision Records

A chronological, immutable log of architectural decisions made during the development of Flourish.

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

---

## Format

Each ADR contains:
- **Decision** — what was decided
- **Context** — why a decision was needed
- **Alternatives considered** — what else was evaluated
- **Consequences** — what changes as a result
