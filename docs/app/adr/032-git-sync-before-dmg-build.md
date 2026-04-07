# ADR-032: Git sync to `main` before DMG build

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

The DMG build script (`scripts/build_dmg.sh`) requires the working tree to be on `main` with no uncommitted changes before it produces a distributable `.dmg`. It runs `git pull origin main` at the start and aborts if the working tree is dirty.

---

## Context

flourish is distributed as a manually-built DMG (no App Store, no notarization pipeline). Historically, DMGs were built from whatever state the working tree happened to be in. This caused two recurring problems:

1. **Stale docs** — the `docs/` folder inside the DMG sometimes reflected an older version of the docs because it was built from a branch that hadn't been merged.
2. **Unreproducible artefacts** — two DMGs with the same version string could contain different binaries if built from different working-tree states.

Requiring a clean `main` sync before the build enforces a single, reproducible source of truth for every release artefact.

---

## Alternatives Considered

### A. Build from any state (original approach)

No constraints on branch or cleanliness. Fast but unreproducible.

Rejected: caused stale-docs incidents and version-string collisions.

### B. Tag-based build gate

Only build when `HEAD` is a tagged commit (`git describe --exact-match`).

Rejected as overly strict for a solo-developer project where patch releases are frequent and tagging every build is unnecessary overhead.

### C. Clean `main` sync (chosen)

The script:
1. Checks `git status --porcelain` — aborts if dirty.
2. Checks the current branch is `main` — aborts otherwise.
3. Runs `git pull origin main` to ensure latest.
4. Proceeds with `xcodebuild archive` + `xcodebuild -exportArchive` + DMG creation.

This is lightweight (no tag ceremony), reproducible (always from latest `main`), and self-documenting.

---

## Consequences

- Developers must commit or stash all changes before running `make dmg` (or `scripts/build_dmg.sh`).
- The build script is the only supported way to produce distributable DMGs; building from Xcode directly is for local testing only.
- CI/CD (if added in the future) should run the same script from a clean `main` checkout.

---

## Related

- [ADR-008: Ad-hoc code signing](008-adhoc-signing.md)
- [ADR-022: Lowercase project name](022-lowercase-project-name.md)
