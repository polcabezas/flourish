# ADR-038: `build-dmg.sh` as the single source of truth for the app version

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

`build-dmg.sh` is the sole place where the release version string is defined. On every run it:

1. Detects the last versioned DMG in the project root and prints it.
2. Prompts the developer for the new version string (e.g. `1.0-beta`, `1.1`, `2.0`).
3. Stamps `flourish/Info.plist` (`CFBundleShortVersionString`) with that value via `PlistBuddy` before invoking `xcodebuild`.
4. Names the output DMG `flourish-<VERSION>.dmg`.

`Info.plist` carries a `dev` placeholder at rest; the build script overwrites it at build time.

The Swift UI reads the version at runtime from `Bundle.main.infoDictionary["CFBundleShortVersionString"]` — no hardcoded strings in view code.

---

## Context

Before this change the version was hardcoded in two places simultaneously:

- `flourish/Info.plist` — `CFBundleShortVersionString = 1.0.0`
- Swift fallback strings in `SettingsPanelView` and `GeneralTab` — `?? "1.0.0"`

Keeping these in sync manually was error-prone. When the UI displayed "Version 1.0.0" it was reading a stale plist value, not a value that had been deliberately set for the release being shipped.

Additionally, all DMGs were named `flourish.dmg`, so building a second release silently overwrote the first with no way to tell the files apart.

---

## Alternatives Considered

### A. Hardcoded version in `Info.plist` (original approach)

Set `CFBundleShortVersionString` by hand before each build.

Rejected: manual step, easy to forget, diverges from the DMG filename.

### B. `MARKETING_VERSION` build setting in `project.yml`

Drive the version from an Xcode build setting so it propagates through the normal Xcode machinery.

Rejected: requires editing `project.yml` and regenerating the project — more steps than a shell prompt, and the XcodeGen round-trip is already slow.

### C. Git tag as version (tag-based)

Read the version from `git describe --tags` at build time.

Rejected: forces a tag commit before every build. Adds ceremony that is unnecessary for a solo-developer project with frequent patch releases.

### D. Interactive prompt in build script (chosen)

The script itself asks "what version is this?" — prints the last DMG as context, then writes the answer into `Info.plist` before building. Single prompt, single source of truth, no extra tooling.

---

## Consequences

- `flourish/Info.plist` holds `dev` at rest; never edit `CFBundleShortVersionString` directly.
- Running `./build-dmg.sh` non-interactively (e.g. from CI) requires piping the version: `echo "1.1" | ./build-dmg.sh`.
- The project root accumulates versioned DMGs (`flourish-1.0-beta.dmg`, `flourish-1.1.dmg`, …); clean them up manually.
- Swift fallback strings in `Bundle.main` lookups should stay as `"dev"` to make it obvious when the app is running from a non-release build.

---

## Related

- [ADR-032: Git sync to `main` before DMG build](032-git-sync-before-dmg-build.md)
- [ADR-008: Ad-hoc code signing](008-adhoc-signing.md)
- [Build and Distribute How-To](../how-to/build-and-distribute.md)
