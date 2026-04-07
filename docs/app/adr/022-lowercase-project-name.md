# ADR-022 — Lowercase project name for all technical identifiers

**Status:** Accepted

---

## Decision

All project-level technical identifiers use lowercase `flourish`:

- Source directory: `flourish/`
- Product name: `flourish` (`PRODUCT_NAME = flourish`)
- Bundle identifier: `com.personal.flourish`
- Xcode scheme: `flourish.xcscheme`
- App bundle: `flourish.app`
- Xcode project file: `flourish.xcodeproj`

Swift type names that include the word "flourish" (e.g. `FlourishApp`, `FlourishColors`) retain PascalCase per Swift naming conventions and are not affected by this decision.

---

## Context

When the project was first set up, Xcode's default behaviour capitalized the product name ("Flourish"). This produced a `Flourish.xcscheme`, `Flourish.app` bundle, and encouraged uppercase path references throughout build scripts and documentation.

Lowercase identifiers are the convention for:
- Unix command-line tools and shell scripts (no quoting needed for paths)
- Bundle IDs (Apple's own convention is all-lowercase reverse-domain)
- Modern repository names on GitHub
- Xcode project and workspace file names that are committed / shared

Keeping the app's _display_ name capitalized as a brand asset is orthogonal to the technical identifier, which should be consistent and case-insensitive-safe.

---

## Alternatives considered

| Option | Reason not chosen |
|--------|-------------------|
| `Flourish` (Title Case) | Xcode default; causes case-sensitivity friction on case-sensitive volumes and in shell scripts |
| `flourish` (all-lowercase) | **Chosen.** Consistent with Unix path conventions, bundle-ID convention, and repo name |

---

## Consequences

- `project.yml` declares `name: flourish`, `PRODUCT_NAME: flourish`, and an explicit `schemes:` block so XcodeGen generates `flourish.xcscheme` deterministically (not left to Xcode's first-open auto-creation).
- Running `make clean && make generate` after this decision removes any stale `Flourish.app` build artifact from local DerivedData and regenerates the project with correct casing.
- Any global Xcode DerivedData entries from before this rename (`~/Library/Developer/Xcode/DerivedData/Flourish-*/`) must be deleted manually if still present.
- Gatekeeper quarantine attributes or system caches that referenced the old `Flourish.app` path are invalidated on next build.

---

## Related

- [ADR-002: XcodeGen over committed .xcodeproj](002-xcodegen.md)
- [Build Configuration Reference](../reference/build-configuration.md)
- [How-To: Build and Distribute](../how-to/build-and-distribute.md)
